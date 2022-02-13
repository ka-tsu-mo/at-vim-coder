from bs4 import BeautifulSoup
import requests
from requests.exceptions import ConnectionError, HTTPError, Timeout
import pickle
import vim
import os
import re
import tex_handler

AT_CODER_BASE_URL = 'https://atcoder.jp'
AT_CODER_LOGIN_URL = AT_CODER_BASE_URL + '/login'

class AtVimCoder:
    def __init__(self):
        self._session = requests.Session()
        self._csrf_token = None
        self._cookies_path = os.path.join(vim.eval('g:at_vim_coder_repo_dir'), 'cookies')
        locale = vim.eval('g:at_vim_coder_locale')
        if locale[:2] == "ja":
            self._locale = "ja"
        else:
            self._locale = "en"
        self._tex_handler = tex_handler.AVCTexHandler()
        if os.path.exists(self._cookies_path):
            with open(self._cookies_path, 'rb') as f:
                self._session.cookies.update(pickle.load(f))

    def get_cookies(self):
        cookies = self._session.cookies.get_dict()
        vim.command(f'let l:cookies = {cookies}')

    def _get_csrf_token(self):
        if self._csrf_token is None:
            try:
                response = self._session.get(AT_CODER_LOGIN_URL, timeout=3.0)
            except (ConnectionError, HTTPError, Timeout):
                raise
            else:
                bs_get_resp = BeautifulSoup(response.text, 'html.parser')
                self._csrf_token =  bs_get_resp.find(attrs={'name': 'csrf_token'}).get('value')
        return self._csrf_token

    def _save_cookies(self):
        with open(self._cookies_path, 'wb') as f:
            pickle.dump(self._session.cookies, f)

    def delete_cookies(self):
        self._session.cookies.clear()
        os.remove(self._cookies_path)

    def logout(self):
        try:
            csrf_token = self._get_csrf_token()
            logout_data = {
                'csrf_token': csrf_token
            }
            response = self._session.post(f'{AT_CODER_BASE_URL}/logout', data=logout_data, allow_redirects=False, timeout=3.0)
        except (ConnectionError, HTTPError, Timeout) as e:
            e_str = str(e)
            vim.command(f'let err = "{e_str}"')
        else:
            if response.status_code == 302:
                vim.command('let logout_success = 1')
            else:
                vim.command('let logout_success = 0')

    def login(self, name, password, save_cookies):
        try:
            csrf_token = self._get_csrf_token()
            login_data = {
                'csrf_token': csrf_token,
                'username': name,
                'password': password
            }
            login_result = self._session.post(AT_CODER_LOGIN_URL, data=login_data, timeout=3.0)
            bs_post_resp = BeautifulSoup(login_result.text, 'html.parser')
        except (ConnectionError, HTTPError, Timeout) as e:
            e_str = str(e)
            vim.command(f'let err = "{e_str}"')
        else:
            if bs_post_resp.find(attrs={'class': 'alert-success'}):
                if save_cookies:
                    self._save_cookies()
                vim.command('let l:login_success = 1')
            else:
                vim.command('let l:login_success = 0')

    def check_login(self):
        url = AT_CODER_BASE_URL + '/settings'
        try:
            response = self._session.get(url, allow_redirects=False, timeout=3.0)
        except (ConnectionError, HTTPError, Timeout) as e:
            e_str = str(e)
            vim.command(f'let err = "{e_str}"')
        else:
            if response.status_code == 302:
                vim.command('let l:logged_in = 0')
            else:
                vim.command('let l:logged_in = 1')


    def create_task_list(self, contest_id):
        try:
            bs_contest_resp = self._download_task_list(contest_id)
        except (ConnectionError, HTTPError, Timeout) as e:
            e_str = str(e)
            vim.command(f'let err = "{e_str}"')
        else:
            if bs_contest_resp is None:
                vim.command('let l:created_task_list = {}')
            else:
                task_table = bs_contest_resp.tbody.find_all('tr')
                task_list = {}
                for task in task_table:
                    task_list_info = task.find_all('td')
                    task_id = task_list_info[0].text
                    task_title = task_list_info[1].text
                    task_url = task_list_info[1].a.get("href")
                    task_list[task_id] = { 'task_title': task_title, 'task_url': task_url }
                vim.command(f'let l:created_task_list= {task_list}')

    def _download_task_list(self, contest_id):
        url = AT_CODER_BASE_URL + '/contests/' + contest_id + f'/tasks?lang={self._locale}'
        try:
            response = self._session.get(url, timeout=3.0)
        except (ConnectionError, HTTPError, Timeout):
            raise
        else:
            if response.status_code == 404:
                return None
            else:
                return BeautifulSoup(response.text, 'html.parser')

    def _get_section_title_by_language(self):
        section_titles = {}
        if self._locale == 'ja':
            section_titles['sample_input'] = '入力例'
            section_titles['sample_output'] = '出力例'
        else:
            section_titles['sample_input'] = 'Sample Input'
            section_titles['sample_output'] = 'Sample Output'
        return section_titles

    def create_task_info(self, url):
        try:
            sections = self._download_task(url)
        except (ConnectionError, HTTPError, Timeout) as e:
            e_str = str(e)
            vim.command(f'let err = "{e_str}"')
        else:
            task_info = {}
            problem_info = []
            sample_input = []
            sample_output = []
            section_titles = self._get_section_title_by_language()
            for section in sections:
                if section.h3 is not None:
                    title = section.h3.text
                else:
                    break
                if title.startswith(section_titles['sample_input']):
                    index = re.search(r'\d+', title).group(0)
                    section.h3.decompose()
                    sample_input.insert(int(index), self._create_sample_io(section, False))
                elif title.startswith(section_titles['sample_output']):
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
            task_info['problem_info'] = problem_info
            task_info['sample_input'] = sample_input
            task_info['sample_output'] = sample_output
            vim.command(f'let l:task_info = {task_info}')

    def _download_task(self, url):
        url = AT_CODER_BASE_URL + url
        try:
            response = self._session.get(url, timeout=3.0)
        except (ConnectionError, HTTPError, Timeout):
            raise
        else:
            bs_task_soup = BeautifulSoup(response.text, 'html.parser')
            if self._locale == 'ja':
                span = bs_task_soup.find('span', attrs={'class': 'lang-ja'})
            else:
                span = bs_task_soup.find('span', attrs={'class': 'lang-en'})
            if span is None:
                return bs_task_soup.find_all('section')
            else:
                return span.find_all('section')

    def _add_single_quote_to_code_tag(self, section):
        code_tags = section.find_all('code')
        for code_tag in code_tags:
            current_text = code_tag.text
            code_tag.string = '\'' + current_text + '\''

    def _create_sample_io(self, section, is_out):
        pre_tag = section.find('pre').contents[0]
        section.pre.decompose()
        if is_out:
            sample_output = {}
            sample_output['value'] = [line for line in pre_tag.splitlines() if line]
            self._tex_handler.replace_var_text(section)
            self._add_single_quote_to_code_tag(section)
            sample_output['explanation'] = [line for line in section.text.splitlines() if line]
            return sample_output
        else:
            return [line for line in pre_tag.splitlines() if line]

    def get_latest_submission(self, contest_id, task_screen_name):
        try:
            tbody = self._download_submissions_list(contest_id, task_screen_name)
        except (ConnectionError, HTTPError, Timeout) as e:
            e_str = str(e)
            vim.command(f'let err = "{e_str}"')
        else:
            td = tbody.tr.find_all('td')
            submission = {
                'time': td[0].text,
                'language': td[3].text,
                'status': td[6].text
            }
            vim.command(f'let latest_submission = {submission}')

    def create_submissions_list(self, contest_id, task_screen_name):
        try:
            tbody = self._download_submissions_list(contest_id, task_screen_name)
        except (ConnectionError, HTTPError, Timeout) as e:
            e_str = str(e)
            vim.command(f'let err = "{e_str}"')
        else:
            if tbody is None:
                vim.command('let submissions_list = []')
                return
            submissions_table = tbody.find_all('tr')
            submissions_list = []
            for tr in submissions_table:
                td = tr.find_all('td')
                submission = {
                    'time': td[0].text,
                    'language': td[3].text,
                    'status': td[6].text
                }
                submissions_list.append(submission)
            submissions_list = sorted(submissions_list, key=lambda x: x['time'])
            vim.command(f'let submissions_list = {submissions_list}')

    def _download_submissions_list(self, contest_id, task_screen_name):
        url = f'{AT_CODER_BASE_URL}/contests/{contest_id}/submissions/me?f.Task={task_screen_name}'
        try:
            response = self._session.get(url, timeout=3.0)
        except (ConnectionError, HTTPError, Timeout):
            raise
        else:
            bs_submissions_resp = BeautifulSoup(response.text, 'html.parser')
            if bs_submissions_resp.tbody is None:
                return None
            else:
                return bs_submissions_resp.tbody
