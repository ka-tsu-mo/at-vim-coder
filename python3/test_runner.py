import subprocess
import sys
import json

def run_test(test_info):
    command = test_info.pop('command')
    task_info = test_info
    sample_input_list = task_info['sample_input']
    sample_output_list = task_info['sample_output']
    test_results = []
    for i in range(len(sample_input_list)):
        sample_input = '\n'.join(sample_input_list[i])
        test_result = {}
        try:
            completed_process = subprocess.run(command, input=sample_input, text=True, capture_output=True, timeout=2)
        except subprocess.TimeoutExpired:
            test_result['status'] = 'TLE'
            test_result['stdout'] = ''
            test_result['stderr'] = ''
        else:
            stdout = completed_process.stdout.replace('\r\n', '\n')
            stderr = completed_process.stderr.replace('\r\n', '\n')
            test_result['stdout'] = stdout.split('\n')
            test_result['stderr'] = stderr.split('\n')
            if test_result['stdout'][:-1] == sample_output_list[i]['value']:
                test_result['status'] = 'AC'
            else:
                test_result['status'] = 'WA'
        test_results.append(test_result)
    return test_results

if __name__=='__main__':
    test_info = json.load(sys.stdin)
    task_id = test_info.pop('task_id')
    result = run_test(test_info)
    print(json.dumps({
        'task_id': task_id,
        'result_list': result
    }))
    sys.exit(0)
