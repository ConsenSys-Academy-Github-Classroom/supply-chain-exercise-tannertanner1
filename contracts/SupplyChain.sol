// SPDX-License-Identifier: MIT
pragma solidity >=0.5.16 <0.9.0;

contract SupplyChain {
  address owner; // <owner>
  uint skuCount; // <skuCount>
  mapping(uint => Item) items; // <items mapping>
  enum State { ForSale, Sold, Shipped, Received } // <enum State: ForSale, Sold, Shipped, Received>

  struct Item { // <struct Item: name, sku, price, state, seller, and buyer>
    string name;
    uint sku;
    uint price;
    State state;
    address payable seller;
    address payable buyer;
  }

  /* events */
  event LogForSale(uint sku); // <LogForSale event: sku arg>
  event LogSold(uint sku); // <LogSold event: sku arg>
  event LogShipped(uint sku); // <LogShipped event: sku arg>
  event LogReceived(uint sku); // <LogReceived event: sku arg>

  /* modifiers */
  modifier isOwner { // <modifier: isOwner>
    require(msg.sender == owner, "Only contract owner can access this function"); // create a modifer, 'isOwner' that checks if the msg.sender is the owner of the contract
    _;
  }
  modifier verifyCaller(address _address) { 
    require(msg.sender == _address, "Caller is not the address provided"); // require (msg.sender == _address); 
    _;
  }
  modifier paidEnough(uint _price) { 
    require(msg.value >= _price, "Not enough payment sent"); // require(msg.value >= _price); 
    _;
  }
  modifier checkValue(uint _sku) { // refund them after pay for item (why it is before, _ checks for logic before func)
    uint _price = items[_sku].price; // uint _price = items[_sku].price;
    uint amountToRefund = msg.value - _price; // uint amountToRefund = msg.value - _price;
    items[_sku].buyer.transfer(amountToRefund); // items[_sku].buyer.transfer(amountToRefund);
    _;
  }
  modifier forSale(uint _sku) { // modifier forSale
   require(items[_sku].state == State.ForSale, "Item is not for sale");
   _;
  }
  modifier sold(uint _sku) { // modifier sold(uint _sku) 
    require(items[_sku].state == State.Sold, "Item is not sold");
   _;
  }
  modifier shipped(uint _sku) { // modifier shipped(uint _sku) 
    require(items[_sku].state == State.Shipped, "Item is not shipped");
    _;
  }
  modifier received(uint _sku) { // modifier received(uint _sku) 
    require(items[_sku].state == State.Received, "Item is not received");
   _;
  }

  constructor() public {
    owner = msg.sender; // 1. set the owner to the transaction sender
    skuCount = 0; // 2. initialize the sku count to 0. question, is this necessary?
  }

  function addItem(string memory _name, uint _price) public returns(bool) {
    items[skuCount] = Item({ // 1. create a new item and put in array
      name: _name,
      sku: skuCount,
      price: _price,
      state: State.ForSale,
      seller: msg.sender,
      buyer: address(0)
    });
    skuCount = skuCount + 1; // 2. increment the skuCount by one
    emit LogForSale(skuCount); // 3. emit the appropriate event
    return true; // 4. return true
  }
  function buyItem(uint sku) public payable forSale(sku) paidEnough(items[sku].price) checkValue(sku) { // 1. it should be payable in order to receive refunds
    items[sku].seller.transfer(items[sku].price); // 2. this should transfer money to the seller
    items[sku].buyer = msg.sender; // 3. set the buyer as the person who called this transaction
    items[sku].state = State.Sold; // 4. set the state to Sold
    // 5. this function should use 3 modifiers to check: if the item is for sale, if the buyer paid enough, and the value after the function is called to make sure the buyer is refunded any excess ether sent
    emit LogSold(sku); // 6. call the event associated with this function
  }
  function shipItem(uint sku) public isOwner sold(sku) { // 1. add modifiers to check: the item is sold already and the person calling this function is the seller
    // require(items[sku].buyer != address(0), "Buyer address is not set");
    items[sku].state = State.Shipped; // 2. change the state of the item to shipped
    emit LogShipped(sku); // 3. call the event associated with this function
  }
  function receiveItem(uint sku) public verifyCaller(items[sku].buyer) shipped(sku) { // 1. add modifiers to check: the item is shipped already and the person calling this function is the buyer
    items[sku].state = State.Received; // 2. change the state of the item to received
    emit LogReceived(sku); // 3. call the event associated with this function
  }

  function fetchItem(uint _sku) public view returns(string memory name, uint sku, uint price, uint state, address seller, address buyer) { // uncomment the following code block needed to run tests
    name = items[_sku].name;
    sku = items[_sku].sku;
    price = items[_sku].price;
    state = uint(items[_sku].state);
    seller = items[_sku].seller;
    buyer = items[_sku].buyer;
    return (name, sku, price, state, seller, buyer);
  }
}
