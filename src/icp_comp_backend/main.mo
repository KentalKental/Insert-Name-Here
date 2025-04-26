import Principal "mo:base/Principal";
import Text "mo:base/Text";
import Source "mo:uuid/Source";
import UUID "mo:uuid/UUID";

module {

  public type BaseProfile = {
    id : Principal;
    role : Text;
    fullName : Text;
    email : Text;
  };
  public type FreelancerProfile = {
    profile : BaseProfile;
    dateOfBirth : Text;
    walletAddress : Text;
    balance : Float;
    profilePictureUrl : Text;
    skills : [Text];
    portfolioIds : ?[Text];
    reputationScore : Float;
    completedProjects : Nat;
    tokenRewards : Float;
    availabilityStatus : Text;
  };

  public type ClientProfile = {
    profile : BaseProfile;
    dateOfBirth : ?Text;
    walletAddress : Text;
    balance : Float;
    profilePictureUrl : Text;
    postedProjects : ?[Text];
    activeContracts : Nat;
  };

  public type AdminProfile = {
    profile : BaseProfile;
    permissions : [Text];
    managedDisputes : ?[Text];
  };

  public type Escrow = {
    id : Principal;
    contractType : Text;
    balance : Float;
    activeContracts : ?[Text];
    executedTransactions : Nat;
    freelancerPayoutRules : Text;
  };

  public type Review = {
    id : Principal;
    jobId : Principal;
    reviewerId : Principal;
    recipientId : Principal;
    rating : Nat;
    comment : Text;
    createdAt : Text;
    freelancerResponse : ?Text;
  };

  public type Transaction = {
    id : Principal;
    jobId : Principal;
    senderId : Principal;
    receiverId : Principal;
    amount : Float;
    currency : Text;
    status : Text;
    createdAt : Text;
    smartContractId : ?Principal;
    transactionHash : ?Text;
    freelancerFeeDeduction : Float;
  };

  public type SavedFavorite = {
    id : Principal;
    userId : Principal;
    itemType : Text;
    itemId : Principal;
    createdAt : Text;
  };

  public type Chat = {
    id : Principal;
    participants : [Principal];
    isChatbot : Bool;
    messages : ?[Message];
    createdAt : Text;
    lastUpdated : Text;
    freelancerPrioritySupport : Bool;
  };

  public type Message = {
    id : Principal;
    senderId : Principal;
    content : Text;
    timestamp : Text;
    messageHash : ?Text;
  };

  public type JobTier = {
    id : Principal;
    name : Text;
    description : Text;
    price : Float;
    currency : Text;
    deliveryDays : Nat;
    revisions : Nat;
    features : [Text];
    freelancerBenefits : [Text];
  };

  public func generateUUID() : async Text {
    let id = Source.Source();
    return UUID.toText(await id.new());
  };

};
