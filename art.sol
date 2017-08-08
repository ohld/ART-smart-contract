pragma solidity ^0.4.11;

contract ARToken {

  struct Account {
    uint rating_sold;
    uint rating_store;
    uint money;
    uint upvotes;
  }

  mapping(address => Account) public accounts;

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

}
