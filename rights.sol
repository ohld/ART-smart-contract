pragma solidity ^0.4.11;

contract Rights {

	struct Account {
		uint rating_sold;
		uint cashback;
		uint money;
		uint upvotes;
		bool is_value;
	}

	struct Content {
		address author;
		address owner;
		address[] sold_to; // Accounts
		address[] reported; // Accounts
		address[] upvoted; // Accounts
		uint price;
		uint flags; // licence type
		bool report_available;
		bool is_value;
	}

	mapping(address => Account) public accounts;

    address public KOSTA; // address of main admin (Kosta Popov)
	address public ARVRFund;

	function Rights() { KOSTA = msg.sender; }

	function set_arvrfund(address fund) {
	    require(KOSTA == msg.sender);
	    ARVRFund = fund;
	}

	// hash_of_the_content => Content struct
	mapping(bytes32 => Content) content;

	/* register new account */
	function register_account() {
		require(accounts[msg.sender].is_value == false);
		accounts[msg.sender] = Account({
			rating_sold: 9000, // %%
			cashback: 0, // %%
			money: 0,
			upvotes: 0,
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

	/* add content with flags and price */
	function add_new_content(bytes32 id, uint price, uint flags) {
		require(content[id].is_value == false); // no content with that id
		require(price >= 0);

		content[id].author = msg.sender;
		content[id].owner = msg.sender;
		content[id].price = price;
		content[id].flags = flags;
		content[id].report_available = true;
		content[id].is_value = true;
	}

	/* buy content with content_id */
	function buy_content(bytes32 id) { // id is content_id: content hash value
		Content storage c = content[id];
		// if id.flags don't allow to buy it: throw;
		require(c.owner != msg.sender);
		require(!ifin(msg.sender, c.sold_to));
		require(accounts[msg.sender].money >= c.price);

		accounts[msg.sender].money -= c.price * (1 - accounts[msg.sender].cashback / 10000);
		accounts[c.owner].money += accounts[c.owner].rating_sold / 10000 * c.price;
		accounts[ARVRFund].money += c.price * (1 - (accounts[c.owner].rating_sold - accounts[msg.sender].cashback) / 10000);
	}

	function transfer_ownership(bytes32 content_id, address new_owner) {
	    require(msg.sender == content[content_id].owner);
	    content[content_id].owner = new_owner;
	}

    function change_flags(bytes32 content_id, uint flags) {
        require(msg.sender == content[content_id].owner);
        content[content_id].flags = flags;
    }

    function change_price(bytes32 content_id, uint new_price) {
        require(msg.sender == content[content_id].owner);
        content[content_id].price = new_price;
    }

    function check_rights(address user, bytes32 content_id) returns (bool) {
        if (content[content_id].owner == user) return true;
        if (ifin(user, content[content_id].sold_to)) return true;
        return false;
    }

	/* ----- ---------- ----- */
	/* ----- moderation ----- */
	/* ----- ---------- ----- */

	address[] public moderators;      // users who have moderation privileges
	bytes32[] public ids_to_moderate; // content_ids what should be moderated

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
				accounts[c.reported[i]].cashback = min(accounts[c.reported[i]].cashback + 10, 500);
			}
			// delete content
			c.author = 0;
			c.owner = 0;
			c.sold_to.length = 0;
			c.flags = 0;
		} else {
			// punish reporters
			for (i = 0; i < c.reported.length; i++) {
				accounts[c.reported[i]].rating_sold = max(accounts[c.reported[i]].rating_sold - 10, 8500);
				accounts[c.reported[i]].cashback = max(accounts[c.reported[i]].cashback - 20, 0);
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
