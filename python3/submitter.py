from bs4 import BeautifulSoup
import requests
from requests import ConnectionError, HTTPError, Timeout
import os
import sys
import pickle
import json

def submit_code(submit_info):
    task_id = submit_info.pop('task_id')
    print(task_id)

    session = requests.Session()
    cookies = submit_info.pop('cookies')
    # set cookies
    if type(cookies) is list:
        cookies_path = os.path.join(*cookies)
        with open(cookies_path, 'rb') as f:
            session.cookies.update(pickle.load(f))
    else: # dict
        for key, value in cookies.items():
            session.cookies.set(key, value)

    contest_id = submit_info.pop('contest_id')
    submit_url = f'https://atcoder.jp/contests/{contest_id}/submit'

    # get csrf token
    try:
        response = session.get(submit_url, timeout=3.0)
    except (ConnectionError, HTTPError, Timeout):
        print(-1)
    else:
        bs_get_resp = BeautifulSoup(response.text, 'lxml')
        csrf_token = bs_get_resp.find(attrs={'name': 'csrf_token'}).get('value')

    task_screen_name = submit_info.pop('task_screen_name')

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

    try:
        submit_result = session.post(submit_url, data=submit_data, timeout=3.0)
    except (ConnectionError, HTTPError, Timeout):
        print(-1)
    else:
        if submit_result.status_code != 200:
            print(-1)
        else:
            print(0)

if __name__=='__main__':
    submit_info = json.load(sys.stdin)
    submit_code(submit_info)
    sys.exit()
