from threading import Event, Thread
import queue

class AvcTaskListUpdater:
	def __init__(self):
		self._update_queue = queue.Queue()
		self.queue_put_event = Event()
