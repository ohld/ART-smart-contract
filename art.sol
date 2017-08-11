pragma solidity ^0.4.11;

contract ARToken {

    /* --- -------------- --- */
	/* --- queue contract --- */
	/* --- -------------- --- */

	struct Queue {
		address[] data;
		uint front;
		uint back;
	}
	/// @dev the number of elements stored in the queue.
	function length(Queue storage q) constant internal returns (uint) {
		return q.back - q.front;
	}
	/// @dev the number of elements this queue can hold
	function capacity(Queue storage q) constant internal returns (uint) {
		return q.data.length - 1;
	}
	/// @dev push a new element to the back of the queue
	function push(Queue storage q, address data) internal
	{
		if ((q.back + 1) % q.data.length == q.front)
			return;
		q.data[q.back] = data;
		q.back = (q.back + 1) % q.data.length;
	}
	/// @dev remove and return the element at the front of the queue
	function pop(Queue storage q) internal returns (address r)
	{
		if (q.back == q.front)
			return;
		r = q.data[q.front];
		delete q.data[q.front];
		q.front = (q.front + 1) % q.data.length;
	}

	/* --- ---------------- --- */
	/* --- artoken contract --- */
	/* --- ---------------- --- */

	struct Account {
		uint rating_sold;
		uint money;
		uint upvotes;
		bool is_value;
	}

	struct Database {
	    bytes32 link;
	    uint rating_store;
		bool is_value;
	}

	mapping(address => Account) public accounts;
	mapping(address => Database) public databases;

	address ARVRFund = 123123123; // should be smart-contract creator?

	struct Content {
		address author;
		address owner;
		address[] sold_to; // Accounts
		Queue stored_at; // Databases
		uint price;
		uint flags; // have not realized yet
		address[] reported; // Accounts
		bool report_available;
		address[] upvoted; // Accounts
		bool is_value;
	}

	// hash_of_the_content => Content struct
	mapping(bytes32 => Content) content;

	/* register new account */
	function register_account() {
		require(accounts[msg.sender].is_value == false);
		accounts[msg.sender] = Account({
			rating_sold: 9000,
			money: 0,
			upvotes: 0,
			is_value: true
		});
	}

	/* register new database */
	function register_database(bytes32 link) {
		require(databases[msg.sender].is_value == false);
		databases[msg.sender] = Database({
			rating_store: 200,
			link: link,
			is_value: true
		});
	}

    /* supportive python-style function */
	function ifin(address a, address[] m) constant returns (bool) {
	    for (uint i = 0; i < m.length; i++)
			if (a == m[i]) return true;
	    return false;
	}

	/* supportive python-style function for bytes32 type arrays */
	function ifinbytes32(bytes32 a, bytes32[]m) constant returns (bool) {
		for (uint i = 0; i < m.length; i++)
			if (a == m[i]) return true;
		return false;
	}

	/* check if content at storage is reachable and valid */
	function is_valid_content_at_storage(address s, bytes32 id) constant returns (bool) {
    	// get request to the user 's' server,
    	// request content by it's hash 'id',
    	// check if 'id' equals hash(content).
		return true;
	}

	/* add content with flags and price */
	function add(bytes32 id, uint price, uint flags) {
		require(content[id].is_value == false);
		require(price >= 0);
		require(is_valid_content_at_storage(msg.sender, id));

		content[id].author = msg.sender;
		content[id].owner = msg.sender;
		content[id].price = price;
		content[id].flags = flags;
		content[id].report_available = true;
		content[id].is_value = true;
// 		content[id].stored_at = new // How to initialize struct properly?
		push(content[id].stored_at, msg.sender); // failes here
	}

	/* get storage_id by content_id */
	function get_storer(bytes32 id) returns (address) {
		// TODO: implementation, returns best match of item in id.stored_at
		Content storage c = content[id];
		while (length(c.stored_at) != 0) {
			address s = pop(c.stored_at); // pop from queue
			if (is_valid_content_at_storage(s, id)) {
				push(c.stored_at, s); // push back to queue
				return s;
			}
		}
		return address(0);
	 }

	/* buy content with content_id */
	function buy(bytes32 id) { // id is content_id: content hash value
		Content storage c = content[id];
		address sid = msg.sender;
		// if id.flags don't allow to buy it: throw;
		require(c.owner != sid);
		require(!ifin(sid, c.sold_to));
		require(accounts[sid].money >= c.price);
		address rewarded_storer = get_storer(id);
		accounts[sid].money -= c.price;
		accounts[c.owner].money += accounts[c.owner].rating_sold / 10000 * c.price;
		accounts[rewarded_storer].money += databases[rewarded_storer].rating_store / 10000 * c.price;
		accounts[ARVRFund].money += c.price * (1 - accounts[c.owner].rating_sold / 10000 - databases[rewarded_storer].rating_store / 10000);
	}

	/* ----- ---------- ----- */
	/* ----- moderation ----- */
	/* ----- ---------- ----- */

	address public KOSTA = 123123123; // address of main admin (Kosta Popov)
																		// who can control over moderators
	address[] public moderators;      // users who have moderation privileges
	bytes32[] public ids_to_moderate; // content_ids what should be moderated

	/* upvote content_id */
	function upvote(bytes32 id) {
		Content storage c = content[id];
		address sid = msg.sender;
		require(!ifin(sid, c.upvoted));
		c.upvoted.push(sid);
		accounts[c.author].upvotes += 1;
	}

	/* report to content_id*/
	function report(bytes32 id) { // TODO: add report type argument
		Content storage c = content[id];
		address sid = msg.sender;
		require(c.report_available == true);
		require(!ifin(sid, c.reported));
		c.reported.push(sid);
		if (c.reported.length > 10 + (accounts[c.author].upvotes) ** 2 / 10000) { // dont know if it would work
			c.report_available = false;
			ids_to_moderate.push(id);
		}
	}

	/* supportive function */
	function max(uint a, uint b) constant returns (uint) {
		if (a > b) return a;
		return b;
	}

	/* supportive function */
	function min(uint a, uint b) constant returns (uint) {
		if (a < b) return a;
		return b;
	}

	/* moderators-only function to decide: delete content or not delete */
	function moderate(bytes32 id, bool vote) {
		uint i = 0;
		Content storage c = content[id];
		address sid = msg.sender;
		require(ifinbytes32(id,ids_to_moderate)); // python syntax
		require(ifin(sid, moderators));
		if (vote) {
			// pay reporters
			for (i = 0; i < c.reported.length; i++) {
				accounts[c.reported[i]].rating_sold = min(accounts[c.reported[i]].rating_sold + 1, 9500);
    			/*accounts[c.reported[i]].rating_store = min(accounts[c.reported[i]].rating_store + 1, 300);*/
			}
			// delete content
			c.author = 0;
			c.owner = 0;
			c.sold_to = new address[](0);
			c.stored_at = Queue({
				data: new address[](0),
				front: 0,
				back: 0
			});
			c.flags = 0;
		} else {
			// punish reporters
			for (i = 0; i < c.reported.length; i++) {
				accounts[c.reported[i]].rating_sold = max(accounts[c.reported[i]].rating_sold - 10, 8500);
				/*accounts[c.reported[i]].rating_store = max(accounts[c.reported[i]].rating_store - 2, 100);*/
			}
		}
	}

	/* admin's method to add moderator */
	function add_moderator(address adr) {
		require(msg.sender == KOSTA);
		if (!ifin(adr, moderators))
			moderators.push(adr); // python syntax
	}

	/* admin's method to delete moderator */
	function del_moderator(address adr) {
		require(msg.sender == KOSTA);
		for (uint i = 0; i < moderators.length; i++) {
				if (moderators[i] == adr) delete(moderators[i]);
		}
	}
}
