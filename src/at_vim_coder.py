from bs4 import BeautifulSoup
import requests
import pickle
import os
import vim

AT_CODER_LOGIN_URL = 'https://atcoder.jp/login/'

class AtVimCoder:
	def __init__(self):
		self._session = requests.Session()
		self._cookies_path = os.path.join(vim.eval('s:at_vim_coder_base_dir'), 'cookies')
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
		self._save_cookies()

		bs_post_resp = BeautifulSoup(login_result.text, 'html.parser')
		if bs_post_resp.find(attrs={'class': 'alert-success'}):
			vim.command('let l:login_result = 1')
		else:
			vim.command('let l:login_result = 0')

	def check_login(self):
		url = 'https://atcoder.jp/settings/'
		response = self._session.get(url, allow_redirects=False)
		if response.status_code == 302:
			vim.command('let l:logged_in = 0')
		else:
			vim.command('let l:logged_in = 1')
