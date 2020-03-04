from bs4 import BeautifulSoup
import requests
import os
import sys
import pickle
import json

def submit_code(submit_info):
	session = requests.Session()
	cookies = submit_info.pop('cookies')
	# set cookies
	if type(cookies) is list:
		cookies_path = os.path.join(*cookies)
		with open(cookies_path, 'rb') as f:
			session.cookies.update(pickle.load(f))
	else: # dict
		for key, value in cookies.items():
			session.cookies.set(key, value.replace('\n', ''))

	contest_id = submit_info.pop('contest_id')
	submit_url = f'https://atcoder.jp/contests/{contest_id}/submit'

	# get csrf token
	response = session.get(submit_url)
	bs_get_resp = BeautifulSoup(response.text, 'lxml')
	csrf_token = bs_get_resp.find(attrs={'name': 'csrf_token'}).get('value')

	task_id = submit_info.pop('task_id')
	print(task_id)
	task_url = submit_info.pop('task_url')
	task_url = task_url.split('/')
	task_screen_name = task_url[-1]

	# get language id
	language = submit_info.pop('language')
	options = bs_get_resp.select(f'#select-lang-{task_screen_name} option')
	language_id = ''
	for option in options:
		if option.text == language:
			language_id = option.get('value')
	if language_id == '':
		print(-1)
		return

	source_code_path_list = submit_info.pop('source_code')
	source_code_path = os.path.join(*source_code_path_list)
	with open(source_code_path, 'r') as f:
		source_code = f.read()

	submit_data = {
			'csrf_token': csrf_token,
			'data.TaskScreenName': task_screen_name,
			'data.LanguageId': language_id,
			'sourceCode': source_code
			}

	submit_result = session.post(submit_url, data=submit_data)
	if submit_result.status_code != 200:
		print(-1)
	else:
		print(0)

if __name__=='__main__':
	submit_info = json.load(sys.stdin, strict=False)
	submit_code(submit_info)
	sys.exit()
