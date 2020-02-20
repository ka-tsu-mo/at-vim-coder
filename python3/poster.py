import requests
import queue

class AvcTestRunner:
	def __init__(self, session, queue):
		self._session = session
		self._buf_sync_queue = queue
		self.requests_queue = queue.Queue()
