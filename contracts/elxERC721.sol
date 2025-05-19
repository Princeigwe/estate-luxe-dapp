// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

import './ERC721.sol';
import './IERC721Receiver.sol';


contract EstateLuxe is ERC721{

  string private _name;
  string private _symbol;

  uint256 tokenIndex;

  struct Realty {
    uint256 tokenId;
    string location;
    string description;
    uint256 price;
    address payable owner;
    bool isForSale;
    string image;
  }

  struct RealtyTxn{
    uint256 tokenId;
    uint256 price;
    address payable seller;
    address payable buyer;
    uint256 date;
  }

  event RealtyListed(
    uint256 tokenId,
    string location,
    string description,
    uint256 price,
    address owner,
    bool isForSale,
    string image
  );

  event RealtyBought(
    uint256 tokenId,
    uint256 price,
    address payable seller,
    address payable buyer,
    uint256 date
  );

  event RealtyResell(
    uint256 tokenId,
    uint256 price,
    bool isForSale
  );


  Realty[] public realties;

    // mapping that return the address of the owner of a specific NFT
  mapping (uint256 => address) private _tokenOwner;

  // mapping that returns the number of NFTs owned by an address
  mapping (address => uint256) private _ownedTokensCount;

  mapping(address => mapping(address => bool)) private _isApprovedForAll;

  mapping(address => mapping(address => mapping(uint256 => bool))) private _isApprovedForSingle;

  mapping(uint256 => address) private _tokenApproval;

  mapping(uint256 => Realty) realtyProperty;

  // returns a list of realty transactions that has occurred, by its token id 
  mapping(uint256 => RealtyTxn[]) realtyTxns;

  mapping(uint256 => string) _tokenUri;

  constructor(string memory name_, string memory symbol_){
    _name = name_;
    _symbol = symbol_;
  }

  // the receive function receives Ether from and EOA to the current contract balance
  receive() external payable{}


  function createListing(
    string memory _location, 
    string memory _description, 
    uint256 _price,
    string memory _image,
    string memory _tokenCid
    ) public {

      require(bytes(_location).length > 0, "Location must not be empty");
      require(bytes(_description).length > 0, "Description must not be empty");
      require(_price > 0, "Price must not be empty");
      require(bytes(_image).length > 0, "Image must not be empty");

      Realty memory realty = Realty({
        tokenId: tokenIndex,
        location: _location,
        description: _description,        
        price: _price,
        owner: payable(msg.sender),
        isForSale: true,
        image: _image
      });
      realtyProperty[tokenIndex]=realty;
      realties.push(realty);
      mint(msg.sender, realty.tokenId);
      setTokenUri(realty.tokenId, _tokenCid);
      tokenIndex ++;
      
      emit RealtyListed(realty.tokenId, realty.location, realty.description, realty.price, realty.owner, realty.isForSale, realty.image);
  }


  function buyRealty(uint256 tokenId)payable public{
    require(_tokenOwner[tokenId] != address(0), "Token does not exist");

    (uint256 _price, address _owner, bool _isForSale)  = findListing(tokenId);
    uint256 money = _price * (1 ether); //converting _price uint value to ether

    require(msg.sender != _owner, "You cannot buy your own property");
    require(msg.value >= money, "Insufficient ETH provided");
    require(_isForSale, "Token is not up for sale");

    if(msg.value > money){
      uint256 overcharge = msg.value - money;
      payable(msg.sender).transfer(overcharge);
    }
    payable(_tokenOwner[tokenId]).transfer(money);

    transferFrom(_tokenOwner[tokenId], msg.sender, tokenId);
    realtyProperty[tokenId].owner = payable(msg.sender);
    realtyProperty[tokenId].isForSale = false;
    
    RealtyTxn memory realtyTxn = RealtyTxn({
      tokenId: tokenId,
      price: _price,
      seller:payable( _tokenOwner[tokenId]),
      buyer: payable(msg.sender),
      date: block.timestamp
    });

    // to keep track of transactions
    realtyTxns[tokenId].push(realtyTxn);

    emit RealtyBought(
      realtyTxn.tokenId,
      realtyTxn.price,
      realtyTxn.seller,
      realtyTxn.buyer,
      realtyTxn.date
    );

  }


  function resellRealty(uint256 _tokenId, uint256 _price)payable public{
    require(_tokenOwner[_tokenId] != address(0), "NFT does not exist");
    require(_tokenOwner[_tokenId] == msg.sender, "Invalid token owner");
    require(_price > 0, "Input realty price");

    Realty memory realty = realtyProperty[_tokenId];
    realty.price = _price;
    realty.isForSale = true;

    emit RealtyResell(realty.tokenId,realty.price, realty.isForSale);
  }

  function getMyRealties()public view returns(uint256[] memory){
    uint256 numberOfTokens = _ownedTokensCount[msg.sender];
    if(numberOfTokens == 0){
      return new uint256[](0);
    }
    else{
      uint256[] memory myRealties = new uint256[](numberOfTokens);
      uint256 myRealtyIndex = 0;
      for (uint256 i = 0; i < realties.length; i++){
        if( realties[i].owner == payable(msg.sender)){
          myRealties[myRealtyIndex] = realties[i].tokenId;
          myRealtyIndex++;
        }
      }
      return myRealties;
    }
  }


  function getRealtyTxns(uint256 _tokenId)public view returns(RealtyTxn[] memory){
    require(_tokenOwner[_tokenId] != address(0), "NFT does not exist");
    return realtyTxns[_tokenId];
  }


  function findListing(uint256 _tokenId)view public returns(
    uint256 _price, 
    address _owner, 
    bool _isForSale
    ){
    Realty memory realty = realtyProperty[_tokenId];
    _price = realty.price; 
    _owner = realty.owner; 
    _isForSale = realty.isForSale; 
    return(
      _price, 
      _owner, 
      _isForSale
    );
  }


  function name() external view returns (string memory) {
    return _name;
  }


  function symbol() external view returns (string memory) {
    return _symbol;
  }
  

  // mint new NFT
  function mint(address _owner, uint256 _tokenId) public {
    // token id should belong to the zero address, meaning that initially, NFT does not exist
    require(_tokenOwner[_tokenId] == address(0), "NFT already minted");

    _tokenOwner[_tokenId] = _owner;
    _ownedTokensCount[_owner] += 1;
    emit Transfer(address(0), _owner, _tokenId);
  }


  // setting token metadata uri with its content identifier (CID)
  function setTokenUri(uint256 _tokenId, string memory _tokenCid)public  {
    require(_tokenOwner[_tokenId] != address(0), "NFT does not exist");
    string memory baseUri = "ipfs://";
    string memory tokenUri = string(abi.encodePacked(baseUri, _tokenCid)); // string concatenation of baseURI with token CID
    _tokenUri[_tokenId] = tokenUri;
  }


  function getTokenUri(uint256 _tokenId) public view returns(string memory) {
    require(_tokenOwner[_tokenId] != address(0), "NFT does not exist");
    return _tokenUri[_tokenId];
  }
  

  // check the number of NFTs owned by an address
  function balanceOf(address _owner) external view returns (uint256 balance){
    return _ownedTokensCount[_owner];
  }


  // check the owner of a specific NFT
  function ownerOf(uint256 _tokenId) external view returns (address owner){
    require(_tokenOwner[_tokenId] != address(0), "NFT does not exist");
    return _tokenOwner[_tokenId];
  }


  // approve another address(operator) to manage the NFT 
  function approve(address _to, uint256 _tokenId) external{
    require(_tokenOwner[_tokenId] == msg.sender, "Invalid token owner");

    _tokenApproval[_tokenId] = _to;
    _isApprovedForSingle[msg.sender][_to][_tokenId] = true;
    emit Approval(msg.sender, _to, _tokenId);
  }


  // get the approved address for a specific NFT
  function getApproved(uint256 _tokenId) external view returns (address operator){
    require(_tokenOwner[_tokenId] != address(0), "NFT does not exist");
    return( _tokenApproval[_tokenId]  );
  }


  // approve of revoke the approval of an operator to handle all NFTs of the owner
  function setApprovalForAll(address _operator, bool _approved) external{
    require(_operator != address(0) , "Invalid operator address");
    require(_operator != msg.sender, "Operator cannot be the owner");
    _isApprovedForAll[msg.sender][_operator] = _approved;
    
    emit ApprovalForAll(msg.sender, _operator, _approved);
  }


  // check if an operator is approved to manage all NFTs of the owner
  function isApprovedForAll(address _owner, address _operator) external view returns (bool){
    require(_owner != address(0), "Invalid owner address");
    require(_operator != address(0), "Invalid operator address");
    return _isApprovedForAll[_owner][_operator];
  }


  // transfer an NFT from one address to another
  function transferFrom(address _from, address _to, uint256 _tokenId) public{
    require(_tokenOwner[_tokenId] != address(0), "NFT does not exist");
    require(_to != address(0), "Invalid recipient");
    require(msg.sender == _tokenOwner[_tokenId] || _isApprovedForSingle[_from][msg.sender][_tokenId] || _isApprovedForAll[_from][msg.sender], "Unauthorized transfer operation");

    _tokenOwner[_tokenId] = _to;
    _ownedTokensCount[_from] -= 1;
    _ownedTokensCount[_to] += 1;

    emit  Transfer(_from, _to, _tokenId);
  }


  // transfer an NFT from one address to another with safety check. designed to revert the transfer of NFTs to contracts that do not support the ERC721 interface
  function safeTransferFrom(address _from, address _to, uint256 _tokenId) external{
    transferFrom(_from, _to, _tokenId);
    // a smart contract address has length of bytecode greater than zero
    // so this checks if the _to address is an EOA, or of the recipient contract is able to handle NFTs with ERC721 interface
    // if none of these is true, the NFT transfer is reverted.
    require(
      _to.code.length==0 || 
      IERC721Receiver(_to).onERC721Received(msg.sender, _from, _tokenId, "") == IERC721Receiver.onERC721Received.selector, "Unsafe recipient" 
    );
  }

}