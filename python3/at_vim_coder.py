from bs4 import BeautifulSoup
import requests
import pickle
import queue
import vim
import sys
import os
import re
import subprocess
import tex_handler

AT_CODER_BASE_URL = 'https://atcoder.jp'
AT_CODER_LOGIN_URL = AT_CODER_BASE_URL + '/login'

class AtVimCoder:
	def __init__(self):
		self.tasks = {}
		"""
		tasks = { 'contest_id': task_list }
		task_list = {
			'task_id': task_info,
		}
		task_info = {
			'task_title': ''
			'problem_info': [], # problem statement, constraints, etc...
			'sample_input': [],
			'sample_output': [{
					'value': '',
					'explanation': ''
			}]
		}
		"""
		self._session = requests.Session()
		self._cookies_path = os.path.join(vim.eval('g:at_vim_coder_repo_dir'), 'cookies')
		self._locale = vim.eval('$LANG')
		self._tex_handler = tex_handler.AVC_tex_handler()
		if os.path.exists(self._cookies_path):
			with open(self._cookies_path, 'rb') as f:
				self._session.cookies.update(pickle.load(f))

	def _get_csrf_token(self):
		response = self._session.get(AT_CODER_LOGIN_URL)
		bs_get_resp = BeautifulSoup(response.text, 'html.parser')
		return bs_get_resp.find(attrs={'name': 'csrf_token'}).get('value')

	def _save_cookies(self):
		with open(self._cookies_path, 'wb') as f:
			pickle.dump(self._session.cookies, f)

	def delete_cookies(self):
		self._session.cookies.clear()
		os.remove(self._cookies_path)

	def login(self, name, password):
		csrf_token = self._get_csrf_token()
		login_data = {
			'csrf_token': csrf_token,
			'username': name,
			'password': password
		}

		login_result = self._session.post(AT_CODER_LOGIN_URL, data=login_data)

		bs_post_resp = BeautifulSoup(login_result.text, 'html.parser')
		if bs_post_resp.find(attrs={'class': 'alert-success'}):
			vim.command('let l:login_result = 1')
			self._save_cookies()
		else:
			vim.command('let l:login_result = 0')

	def check_login(self):
		url = AT_CODER_BASE_URL + '/settings'
		response = self._session.get(url, allow_redirects=False)
		if response.status_code == 302:
			vim.command('let l:logged_in = 0')
		else:
			vim.command('let l:logged_in = 1')

	def get_task_list(self, contest_id):
		vim.command(f'let l:task_list = {self.tasks[contest_id]}')

	def get_task_info(self, contest_id, task_id):
		if 'problem_info' not in self.tasks[contest_id][task_id]:
			task_url = self.tasks[contest_id][task_id]['task_url']
			self.tasks[contest_id][task_id].update(self._create_task_info(task_url))
		vim.command(f'let l:task_info = {self.tasks[contest_id][task_id]}')

	def create_tasks(self, contest_id):
		task_list = self._create_task_list(contest_id)
		if task_list is None:
			vim.command('let l:created_tasks = {}')
		else:
			self.tasks[contest_id] = task_list
			vim.command(f'let l:created_tasks = {self.tasks[contest_id]}')

	def _create_task_list(self, contest_id):
		bs_contest_resp = self._download_task_list(contest_id)
		if bs_contest_resp is None:
			return None
		else:
			task_table = bs_contest_resp.tbody.findAll('tr')
			task_list = {}
			for task in task_table:
				task_list_info = task.findAll('td')
				task_id = task_list_info[0].text
				task_title = task_list_info[1].text
				task_url = task_list_info[1].a.get("href")
				task_list[task_id] = { 'task_title': task_title, 'task_url': task_url }
			return task_list

	def _download_task_list(self, contest_id):
		url = AT_CODER_BASE_URL + '/contests/' + contest_id + '/tasks'
		response = self._session.get(url)
		if response.status_code == 404:
			return None
		else:
			return BeautifulSoup(response.text, 'html.parser')

	def _create_task_info(self, url):
		sections = self._download_task(url)
		task_info = {}
		problem_info = []
		sample_input = []
		sample_output = []
		if self._locale[:2] == 'ja':
			for section in sections:
				title = section.h3.text
				if title.startswith('入力例'):
					index = re.search(r'\d+', title).group(0)
					section.h3.decompose()
					sample_input.insert(int(index), self._create_sample_io(section, False))
				elif title.startswith('出力例'):
					index = re.search(r'\d+', title).group(0)
					section.h3.decompose()
					sample_output.insert(int(index), self._create_sample_io(section, True))
				else:
					problem_info.append('['+section.h3.text+']')
					section.h3.decompose()
					self._tex_handler.replace_var_text(section)
					self._add_single_quote_to_code_tag(section)
					lines = [line.strip() for line in section.text.splitlines() if line]
					problem_info.extend(lines)
		else:
			for section in sections:
				title = section.h3.text
				if title.startswith('Sample Input'):
					index = re.search(r'\d+', title).group(0)
					section.h3.decompose()
					sample_input.insert(int(index), self._create_sample_io(section, False))
				elif title.startswith('Sample Output'):
					index = re.search(r'\d+', title).group(0)
					section.h3.decompose()
					sample_output.insert(int(index), self._create_sample_io(section, True))
				else:
					problem_info.append('['+section.h3.text+']')
					section.h3.decompose()
					self._tex_handler.replace_var_text(section)
					lines = [line.strip() for line in section.text.splitlines() if line]
					problem_info.extend(lines)
		task_info['problem_info'] = problem_info
		task_info['sample_input'] = sample_input
		task_info['sample_output'] = sample_output
		return task_info

	def _download_task(self, url):
		url = AT_CODER_BASE_URL + url
		response = self._session.get(url)
		bs_task_soup = BeautifulSoup(response.text, 'html.parser')
		if self._locale[:2] == 'ja':
			span = bs_task_soup.find('span', attrs={'class': 'lang-ja'})
		else:
			span = bs_task_soup.find('span', attrs={'class': 'lang-en'})
		if span is None:
			return bs_task_soup.findAll('section')
		else:
			return span.findAll('section')

	def _add_single_quote_to_code_tag(self, section):
		code_tags = section.findAll('code')
		for code_tag in code_tags:
			current_text = code_tag.text
			code_tag.string = '\'' + current_text + '\''

	def _create_sample_io(self, section, is_out):
		pre_tag = section.find('pre').contents[0]
		section.pre.decompose()
		if is_out:
			sample_output = {}
			sample_output['value'] = [line for line in pre_tag.splitlines()]
			self._tex_handler.replace_var_text(section)
			self._add_single_quote_to_code_tag(section)
			sample_output['explanation'] = [line for line in section.text.splitlines() if line]
			return sample_output
		else:
			return [line for line in pre_tag.splitlines()]
