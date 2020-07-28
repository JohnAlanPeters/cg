from SimpleWebSocketServer import SimpleWebSocketServer, WebSocket
from thread import *
import time
import pdb

socks=0

def outf():
    while True:
        stxt=raw_input()
        socks.sendMessage(u''+stxt)

class SimpleSock(WebSocket):
    def handleMessage(self):
        print self.data

    def handleConnected(self):
        global socks
        print(self.address, 'connected')
        #socks.append(self)
        socks=self
        start_new_thread(outf,())

    def handleClose(self):
        print(self.address, 'closed')
    
server = SimpleWebSocketServer('', 8000, SimpleSock)
server.serveforever()    

