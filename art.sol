pragma solidity ^0.4.11;

contract ARToken {

  struct Account { // TODO: set initial values for every field
    uint rating_sold; // 900 from 850 to 950
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
    address[] stored_at;
    uint price;
    uint flags;
    address[] reported;
    bool report_available;
    address[] upvoted;
  }

  // hash_of_the_content_by_link => Content struct
  mapping(bytes32 => Content) content;

  function register() {
    acounts[msg.sender] = Account({
      rating_sold: 900,
      rating_store: 200,
      money: 0,
      upvotes: 0
    });
  }

  function add(bytes64 link, uint price, uint flags) {
    // TODO: check if content by link is valid
    // link is concatenation "Account.address" + "Content.hash (bytes32)"
    // content_id is hash_of_the_content_by_link
    content["hash_of_the_content_by_link"] = Content({
                author: msg.sender,
                owner: msg.sender,
                sold_to: [],
                stored_at: [msg.sender],
                price: price,
                flags: flags,
                reported: [],
                report_available: true,
                upvoted: [],
    });
  }

  function buy(bytes32 id) { // id is content_id: content hash value
    Content c = content[id];
    address sid = msg.sender;
    // if id.flags don't allow to buy it: throw;
    if (c.owner == sid || sid in c.sold_to) throw; { // python syntax
    if (sid.money < c.price) throw;
    rewarded_storer = get_storer(id);
    sid.money -= c.price;
    c.owner.money += c.owner.rating_sold / 1000 * c.price;
    rewarded_storer.money += rewarded_storer.rating_store / 10000 * c.price;
    ARVRFund.money += c.price * (1 - c.owner.rating_sold / 1000 - rewarded_storer.rating_store / 10000);
  }

  function get_storer(bytes32 id) returns (address) {
    // TODO: implementation, returns best match of item in id.stored_at
    Content c = content[id];
    while (c.stored_at.length != 0) {
      s = c.stored_at.pop(); // pop from queue
      if is_valid_storage(s) {
        c.stored_at.add(s); // push to queue
        return c;
      }
    }
    return 0 // invalid address
  }

  function is_valid_storage(address storage) returns (bool is_valid) {
    is_valid = true
  }

  /* ----- moderation ----- */

  address public KOSTA = 123123123; // address of main admin (Kosta Popov)
  address[] public moderators;
  bytes32[] public ids_to_moderate; // content_ids

  function upvote(bytes32 id) {
    Content c = content[id];
    address sid = msg.sender;
    if (sid in c.upvoted) throw; // python syntax
    c.upvoted.append(sid);
    c.author.upvotes += 1
  }

  function report(bytes32 id) { // TODO: add report type argument
    Content c = content[id];
    address sid = msg.sender;
    if (c.report_available == 0) throw;
    if (sid in c.reported) throw; // python syntax
    c.reported.append(sid);
    if (c.reported.length > 10 + 10 ** (-5) * (c.author.upvotes) ** 2) {
      c.report_available = 0;
      ids_to_moderate.append(id);
    }
  }

  function max(uint a, uint b) returns (uint) {
    if (a > b) return a;
    return b;
  }

  function moderate(bytes32 id, bool vote) {
    Content c = content[id];
    address sid = msg.sender;
    if (id not in ids_to_moderate) throw; // python syntax
    if (sid not in moderators) throw; // python syntax
    if (vote) {
      // delete content
      c.author = 0;
      c.owner = 0;
      c.sold_to = [];
      c.stored_at = [];
      c.flags = 0;
      // pay reporters
      for i in c.reported { // python syntax
        i.rating_sold = min(i.rating_sold + 1, 950)
        i.rating_store = min(i.rating_store + 1, 300)
      }
    } else {
      // punish reporters
      for i in c.reported { // python syntax
        i.rating_sold = max(i.rating_sold - 10, 850)
        i.rating_store = max(i.rating_store - 2, 100)
      }
    }
  }

  function add_moderator(address adr) {
    address sid = msg.sender;
    if (sid != KOSTA) throw;
    if (adr not in moderators) // python syntax
      moderators.append(adr) // python syntax
  }

  function del_moderator(address adr) {
    address sid = msg.sender;
    if (sid != KOSTA) throw;
    if (adr in moderators) // python syntax
      moderators.delete(adr) // python syntax
  }
}
