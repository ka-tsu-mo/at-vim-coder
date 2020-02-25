import subprocess
import sys
import json

def run_test(test_info):
	command = test_info.pop('command')
	task_info = test_info
	sample_input_list = task_info['sample_input']
	sample_output_list = task_info['sample_output']
	for i in range(len(sample_input_list)):
		sample_input = '\n'.join(sample_input_list[i])
		sample_output = '\n'.join(sample_output_list[i]['value'])
		test_result = {}
		try:
			completed_process = subprocess.run(command, input=sample_input, text=True, capture_output=True, timeout=2)
		except subprocess.TimeoutExpired as e:
			test_result['status'] = 'TLE'
			test_result['stdout'] = e.stdout
			test_result['stderr'] = e.stderr
		else:
			test_result['stdout'] = completed_process.stdout
			test_result['stderr'] = completed_process.stderr
			if completed_process.stdout[:-1] == sample_output:
				test_result['status'] = 'AC'
			else:
				test_result['status'] = 'WA'
		print(test_result)

if __name__=='__main__':
	test_info = json.load(sys.stdin)
	run_test(test_info)
	sys.exit()