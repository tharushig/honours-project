from web3 import Web3
import psycopg2

# Connect to alchemy
w3 = Web3(Web3.HTTPProvider('https://eth-sepolia.g.alchemy.com/v2/PoofjHudh-iVcFkt8gbk5MYv2vxK1vJw'))

# vdr contract integration
contract_address = '0xD7B144c4759FFd5EAe081c07927Ae015d79676F5'
abi = [
	{
		"anonymous": False,
		"inputs": [
			{
				"indexed": False,
				"internalType": "uint256",
				"name": "proj_id",
				"type": "uint256"
			},
			{
				"indexed": False,
				"internalType": "string",
				"name": "methodology",
				"type": "string"
			},
			{
				"indexed": False,
				"internalType": "bool",
				"name": "passed",
				"type": "bool"
			},
			{
				"indexed": False,
				"internalType": "string",
				"name": "notes",
				"type": "string"
			}
		],
		"name": "MonitoringSubmitted",
		"type": "event"
	},
	{
		"anonymous": False,
		"inputs": [
			{
				"indexed": False,
				"internalType": "uint256",
				"name": "id",
				"type": "uint256"
			},
			{
				"indexed": False,
				"internalType": "string",
				"name": "name",
				"type": "string"
			},
			{
				"indexed": False,
				"internalType": "string",
				"name": "methodology",
				"type": "string"
			},
			{
				"indexed": False,
				"internalType": "uint256",
				"name": "expected_reductions",
				"type": "uint256"
			},
			{
				"indexed": False,
				"internalType": "string",
				"name": "location",
				"type": "string"
			},
			{
				"indexed": False,
				"internalType": "uint256",
				"name": "start_date",
				"type": "uint256"
			},
			{
				"indexed": False,
				"internalType": "uint256",
				"name": "verification_date",
				"type": "uint256"
			},
			{
				"indexed": False,
				"internalType": "uint256",
				"name": "validation_date",
				"type": "uint256"
			},
			{
				"indexed": False,
				"internalType": "uint256",
				"name": "issued_credits",
				"type": "uint256"
			}
		],
		"name": "ProjectInfoSubmitted",
		"type": "event"
	},
	{
		"inputs": [
			{
				"internalType": "uint256",
				"name": "proj_id",
				"type": "uint256"
			},
			{
				"internalType": "string",
				"name": "methodology",
				"type": "string"
			},
			{
				"internalType": "bool",
				"name": "passed",
				"type": "bool"
			},
			{
				"internalType": "string",
				"name": "notes",
				"type": "string"
			}
		],
		"name": "submitMonitoring",
		"outputs": [],
		"stateMutability": "nonpayable",
		"type": "function"
	},
	{
		"inputs": [
			{
				"internalType": "uint256",
				"name": "id",
				"type": "uint256"
			},
			{
				"internalType": "string",
				"name": "name",
				"type": "string"
			},
			{
				"internalType": "string",
				"name": "methodology",
				"type": "string"
			},
			{
				"internalType": "uint256",
				"name": "expected_reductions",
				"type": "uint256"
			},
			{
				"internalType": "string",
				"name": "location",
				"type": "string"
			},
			{
				"internalType": "uint256",
				"name": "start_date",
				"type": "uint256"
			},
			{
				"internalType": "uint256",
				"name": "verification_date",
				"type": "uint256"
			},
			{
				"internalType": "uint256",
				"name": "validation_date",
				"type": "uint256"
			},
			{
				"internalType": "uint256",
				"name": "issued_credits",
				"type": "uint256"
			}
		],
		"name": "submitProjectInfo",
		"outputs": [],
		"stateMutability": "nonpayable",
		"type": "function"
	}
]

contract = w3.eth.contract(address=contract_address, abi=abi)


# # Connect to psql
conn = psycopg2.connect(database="****", user="****", password="****", host="localhost", port=5433)
cursor = conn.cursor()

# Handling verification phase
def handle_lock(event):
    data = event['args']
    proj_id = data['id']
    methodology = data['methodology']
    location = data['location']
    name = data['name']
    expected_reductions = data['expected_reductions']
    start_date = data['start_date']
    verification_date = data['verification_date']
    validation_date = data['validation_date']
    issued_credits = data['issued_credits']

    print("Inserting into DB:", data)

    cursor.execute(
        "INSERT INTO public.registry (id,name,methodology,expected_reductions,location,start_date,verification_date,validation_date,issued_credits) VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s)",
        (proj_id,name,methodology,expected_reductions,location,start_date,verification_date,validation_date,issued_credits)
    )
    conn.commit()

# Handling monitoring phase
def handle_alert(event):
    data = event['args']
    proj_id = data['proj_id']
    methodology = data['methodology']
    passed = data['passed']
    notes = data['notes']

    print("Inserting into DB:", data)

    cursor.execute(
        "INSERT INTO public.monitoring (id,passed,methodology,notes) VALUES (%s, %s, %s, %s)",
        (proj_id,passed,methodology,notes)
    )
    conn.commit()


event_filter = contract.events.MonitoringSubmitted.create_filter(from_block='latest')
event_filter2 = contract.events.ProjectInfoSubmitted.create_filter(from_block='latest')


# Listens for emitted messages
print("Listening for events...")
while True:
    for event in event_filter.get_new_entries():
        handle_alert(event)
    for event in event_filter2.get_new_entries():
        handle_lock(event)