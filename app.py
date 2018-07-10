import web3
import json
from web3 import Web3



def init(me):
  global w3
  w3 = Web3(Web3.HTTPProvider("http://127.0.0.1:7545", request_kwargs={'timeout': 60}))
  contractAddress = '0x115f75f4db4571c3A49633aA1276181039B4Df41'
  global myAddress
  myAddress = me
  with open('www/build/contracts/Entity.json','r') as abi_def:
    info = json.load(abi_def)
  global contract 
  contract = w3.eth.contract(contractAddress, abi=info["abi"])
  return getUser(myAddress)

def getUser(address):
  return contract.functions.getUser(address).call()
  
def addUser(address, userType):
  txHash = contract.functions.addUser(ad(address), Web3.toInt(userType)).transact({'from': w3.eth.accounts[0]})
  txReceipt = w3.eth.waitForTransactionReceipt(txHash)
  return int(txReceipt, 16)
  
def getRequest(address, index):
  return contract.functions.getRequest(ad(address), Web3.toInt(index)).call({'from': w3.eth.accounts[3]})
  
def requestClaim(address, status, desc):
  txHash = contract.functions.requestClaim(ad(address), Web3.toInt(status), desc).transact({'from': w3.eth.accounts[3]})
  txReceipt = w3.eth.waitForTransactionReceipt(txHash)
  return txReceipt
  
def ad(address):
  return Web3.toChecksumAddress(Web3.toHex(hexstr=address))
  
def usr():
  return w3.eth.accounts

def setU(i):
  w3.eth.defaultAccount = w3.eth.accounts[i]

