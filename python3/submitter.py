from bs4 import BeautifulSoup
import requests
from requests import ConnectionError, HTTPError, Timeout
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
            session.cookies.set(key, value)

    contest_id = submit_info.pop('contest_id')
    submit_url = f'https://atcoder.jp/contests/{contest_id}/submit'

    # get csrf token
    try:
        response = session.get(submit_url, timeout=3.0)
    except (ConnectionError, HTTPError, Timeout) as e:
        return str(e)
    else:
        bs_get_resp = BeautifulSoup(response.text, 'html.parser')
        csrf_token_attr = bs_get_resp.find(attrs={'name': 'csrf_token'})
        if csrf_token_attr is None:
            return 'Failed to get CSRF token.'

    csrf_token = csrf_token_attr.get('value')
    task_screen_name = submit_info.pop('task_screen_name')

    # get language id
    language = submit_info.pop('language')
    options = bs_get_resp.select(f'#select-lang-{task_screen_name} option')
    language_id = ''
    for option in options:
        if option.text == language:
            language_id = option.get('value')
    if language_id == '':
        return 'Failed to get language id on submit page.'

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
    except (ConnectionError, HTTPError, Timeout) as e:
        return str(e)
    if submit_result.status_code != 200:
        return f"Error on submit(status code: {submit_result.status_code})"
    else:
        return "success"

if __name__=='__main__':
    submit_info = json.load(sys.stdin)
    task_id = submit_info.pop('task_id')
    result = submit_code(submit_info)
    print(json.dumps({
        'task_id': task_id,
        'result': result
    }))
    sys.exit(0)
