from bs4 import BeautifulSoup
import requests
import pickle
import vim
import sys
import os
sys.path.insert(0, os.path.join(vim.eval('s:at_vim_coder_repo_dir'), 'py'))
import tex_handler

AT_CODER_BASE_URL = 'https://atcoder.jp'
AT_CODER_LOGIN_URL = AT_CODER_BASE_URL + '/login'

class AtVimCoder:
	def __init__(self):
		self._session = requests.Session()
		self._cookies_path = os.path.join(vim.eval('s:at_vim_coder_repo_dir'), 'cookies')
		self._tex_handler = tex_handler.AVC_tex_handler()
		self._locale = vim.eval('$LANG')
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
		bs_contest_resp = self._download_task_list(contest_id)
		if bs_contest_resp == None:
			vim.command('let task_list = {}')
		else:
			task_table = bs_contest_resp.tbody.findAll('tr')
			self.contest_id = contest_id
			tasks = {}
			for task in task_table:
				task_info = task.findAll('td')
				task_id = task_info[0].text
				task_title = task_info[1].text
				task_url = task_info[1].a.get("href")
				tasks[task_id] = [task_title, task_url]
			vim.command(f'let task_list = {tasks}')


	def _download_task_list(self, contest_id):
		url = AT_CODER_BASE_URL + '/contests/' + contest_id + '/tasks'
		response = self._session.get(url)
		if response.status_code == 404:
			return None
		else:
			return BeautifulSoup(response.text, 'html.parser')

	def get_task(self, url):
		sections = self._download_task(url)
		task = []
		if self._locale[:2] == 'ja':
			part = ['問題文', '制約', '入力', '出力']
			for section in sections:
				if part == []: break
				if section.h3.text in part:
					task.append('['+section.h3.text+']')
					section.h3.decompose()
					self._tex_handler.replace_var_text(section)
					lines = [line.strip() for line in section.text.splitlines() if line]
					task.extend(lines)
		else:
			part = ['Problem Statement', 'Constraints', 'Input', 'Output']
			for section in sections:
				if section.h3.text in part:
					task.append('['+section.h3.text+']')
					section.h3.decompose()
					self._tex_handler.replace_var_text(section)
					lines = [line.strip() for line in section.text.splitlines() if line]
					task.extend(lines)
		vim.command(f'let task = {task}')

	def _download_task(self, url):
		url = AT_CODER_BASE_URL + url
		response = self._session.get(url)
		bs_task_soup = BeautifulSoup(response.text, 'html.parser')
		return bs_task_soup.findAll('section')

Avc = AtVimCoder()
