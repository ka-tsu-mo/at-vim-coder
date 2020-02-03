from bs4 import BeautifulSoup
import requests
import vim

avc_session = requests.Session()

def avc_login(name, password):
	url = "https://atcoder.jp/login/"
	with avc_session as s:
		response = s.get(url)
		bs_get_resp = BeautifulSoup(response.text, 'html.parser')
		csrf_token = bs_get_resp.find(attrs={'name': 'csrf_token'}).get('value')
		login_data = {
			"csrf_token": csrf_token,
			"username": name,
			"password": password
		}

		login_result = s.post(url, data=login_data)
		bs_post_resp = BeautifulSoup(login_result.text, 'html.parser')
		if bs_post_resp.find(attrs={'class': 'alert-success'}):
			vim.command("let l:login_result = 1")
		else:
			vim.command("let l:login_result = 0")

def avc_check_login():
	url = "https://atcoder.jp/settings/"
	response = avc_session.get(url, allow_redirects=False)
	if response.status_code == 302:
		vim.command("let l:logged_in = 0")
	else:
		vim.command("let l:logged_in = 1")
