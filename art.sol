pragma solidity ^0.4.11;

// queue https://github.com/chriseth/solidity-examples/blob/master/queue.sol
contract queue
{
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
            return; // throw;
        q.data[q.back] = data;
        q.back = (q.back + 1) % q.data.length;
    }
    /// @dev remove and return the element at the front of the queue
    function pop(Queue storage q) internal returns (address r)
    {
        if (q.back == q.front)
            return; // throw;
        r = q.data[q.front];
        delete q.data[q.front];
        q.front = (q.front + 1) % q.data.length;
    }
}

contract ARToken {

  struct Account { // TODO: set initial values for every field
    uint rating_sold; // 9000 from 8500 to 9500
    uint rating_store; // 200 from 100 to 300
    uint money; // 0
    uint upvotes; // 0
  }

  mapping(address => Account) public accounts;
  Account ARVRFund;

  struct Content {
    address author;
    address owner;
    address[] sold_to;
    queue stored_at;
    uint price;
    uint flags;
    address[] reported;
    bool report_available;
    address[] upvoted;
  }

  // hash_of_the_content_by_link => Content struct
  mapping(bytes32 => Content) content;

  /* register new user */
  function register() {
    accounts[msg.sender] = Account({
      rating_sold: 9000,
      rating_store: 200,
      money: 0,
      upvotes: 0
    });
  }

  /* supportive python-style function */
  function ifin(address a, address[]m) returns (bool) {
    for (uint i = 0; i < m.length; i++)
      if (a == m[i]) return true;
    return false;
  }

  /* supportive python-style function for bytes32 type arrays*/
  function ifinbytes32(bytes32 a, bytes32[]m) returns (bool) {
    for (uint i = 0; i < m.length; i++)
      if (a == m[i]) return true;
    return false;
  }

  /* check if content at storage is reachable and valid */
  function is_valid_content_at_storage(address s, bytes32 id) returns (bool) {
    // id - hash of the file.
    // storage - address of the user who store that content
    // TODO: logic
    // Check if this user store this content (availability)
    // Check if hash of the file with this id equals to id (consistency)
    return true;
  }

  /* add content with flags and price */
  function add(bytes32 id, uint price, uint flags) {
    // TODO: check if content by link is valid
    // link is concatenation "Account.address" + "Content.hash (bytes32)"
    // content_id is hash_of_the_content_by_link
    require(content[id].author == address(0x0)); // content with that id is in the base
    require(is_valid_content_at_storage(msg.sender, id));
    require(price >= 0);
    content[id] = Content({
      author: msg.sender,
      owner: msg.sender,
      sold_to: new address[](0),
      stored_at: new queue,
      price: price,
      flags: flags,
      reported: new address[](0),
      report_available: true,
      upvoted: new address[](0)
    });
    queue.push(content[id].stored_at, msg.sender);
  }

  /* buy content with content_id */
  function buy(bytes32 id) { // id is content_id: content hash value
    Content storage c = content[id];
    address sid = msg.sender;
    // if id.flags don't allow to buy it: throw;
    require(c.owner != sid && !ifin(sid, c.sold_to));
    require(sid.money >= c.price);
    address rewarded_storer = get_storer(id);
    sid.money -= c.price;
    c.owner.money += c.owner.rating_sold / 10000 * c.price;
    rewarded_storer.money += rewarded_storer.rating_store / 10000 * c.price;
    ARVRFund.money += c.price * (1 - c.owner.rating_sold / 10000 - rewarded_storer.rating_store / 10000);
  }

  /* get storage_id by content_id */
  function get_storer(bytes32 id) returns (address) {
    // TODO: implementation, returns best match of item in id.stored_at
    Content storage c = content[id];
    while (c.stored_at.length != 0) {
      address s = c.stored_at.pop(); // pop from queue
      if (is_valid_content_at_storage(s, id)) {
        c.stored_at.push(s); // push back to queue
        return c;
      }
    }
    return address(0);
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
    c.author.upvotes += 1;
  }

  /* report to content_id*/
  function report(bytes32 id) { // TODO: add report type argument
    Content storage c = content[id];
    address sid = msg.sender;
    require(c.report_available == true);
    require(!ifin(sid, c.reported));
    c.reported.push(sid);
    if (c.reported.length > 10 + 10 ** (-5) * (c.author.upvotes) ** 2) { // dont know if it would work
      c.report_available = false;
      ids_to_moderate.push(id);
    }
  }

  /* supportive function */
  function max(uint a, uint b) returns (uint) {
    if (a > b) return a;
    return b;
  }

    /* supportive function */
  function min(uint a, uint b) returns (uint) {
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
      // delete content
      c.author = 0;
      c.owner = 0;
      c.sold_to = [];
      c.stored_at = [];
      c.flags = 0;
      // pay reporters
      for (i = 0; i < c.reported.length; i++) {
        c.reported[i].rating_sold = min(c.reported[i].rating_sold + 1, 9500);
        c.reported[i].rating_store = min(c.reported[i].rating_store + 1, 300);
      }
    } else {
      // punish reporters
      for (i = 0; i < c.reported.length; i++) {
        c.reported[i].rating_sold = max(c.reported[i].rating_sold - 10, 8500);
        c.reported[i].rating_store = max(c.reported[i].rating_store - 2, 100);
      }
    }
  }

  /* admin's method to add moderator */
  function add_moderator(address adr) {
    address sid = msg.sender;
    require(sid == KOSTA);
    if (!ifin(adr, moderators))
      moderators.push(adr); // python syntax
  }

  /* admin's method to delete moderator */
  function del_moderator(address adr) {
    address sid = msg.sender;
    require(sid == KOSTA);
    for (uint i = 0; i < moderators.length; i++) {
        if (moderators[i] == adr) delete(moderators[i]);
    }
  }
}
