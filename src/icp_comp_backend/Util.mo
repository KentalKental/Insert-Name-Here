import Principal "mo:base/Principal";
import Text "mo:base/Text";
// import Source "mo:uuid/Source";
// import UUID "mo:uuid/UUID";

module {

  // Base user profile shared by all users
  public type BaseProfile = {
    id : Principal;
    fullName : Text;
    email : Text;
    bio : Text;
    profilePictureUrl : Text;
    phoneNumber : Text;
    location : Text;
    rating : ?Float; // Optional until they get reviews
    createdAt : Text;
  };

  // Freelancer-specific profile extension
  public type FreelancerProfile = {
    profile : BaseProfile;
    dateOfBirth : Text;
    walletAddress : Text;
    balance : Float;
    skills : [Text];
    portfolioIds : ?[Text]; // Optional: Not all freelancers have a portfolio yet
    reputationScore : Float; // Based on reviews, orders, etc.
    completedProjects : Nat;
    tokenRewards : Float; // For gamification or loyalty points
    availabilityStatus : Text; // "Available", "Busy", "On Vacation", etc.
  };

  // Client-specific profile extension
  public type ClientProfile = {
    profile : BaseProfile;
    dateOfBirth : ?Text; // Optional for clients
    walletAddress : Text;
    balance : Float;
    postedProjects : ?[Text]; // IDs of gigs they posted
    activeContracts : Nat; // Number of ongoing orders
  };

  // Admin-specific profile extension
  public type AdminProfile = {
    profile : BaseProfile;
    permissions : [Text]; // Example: ["banUser", "resolveDispute"]
    managedDisputes : ?[Text]; // IDs of disputes they handled
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

  public type Escrow = {
    id : Principal;
    contractType : Text;
    balance : Float;
    activeContracts : ?[Text];
    executedTransactions : Nat;
    freelancerPayoutRules : Text;
  };

  public type SavedFavorite = {
    id : Principal;
    userId : Principal;
    itemType : Text;
    itemId : Principal;
    createdAt : Text;
  };

  // CHAT SYSTEM START

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
  // CHAT SYSTEM END

  // JOBS SYSTEM START

  // Enum for job/service/order status
  public type JobStatus = {
    #Pending;
    #Active;
    #InProgress;
    #Delivered;
    #Completed;
    #Cancelled;
    #Disputed;
  };

  // Enum for payment method
  public type PaymentMethod = {
    #Escrow;
    #Direct;
  };

  // Enum for contract type
  public type ContractType = {
    #FixedPrice;
    #Hourly;
  };

  // Order represents a transaction between client and freelancer
  public type Order = {
    id : Text;
    clientId : Principal;
    freelancerId : Principal;
    serviceId : Principal;
    packageId : Text;
    status : JobStatus;
    createdAt : Nat;
    updatedAt : Nat;
    paymentStatus : Text; // "Pending", "Paid", "Refunded", "Disputed"
    amount : Nat; // In smallest currency unit (e.g., cents)
    currency : Text; // "USD", "EUR"
    deliveryDeadline : Nat; // Timestamp deadline
    cancellationReason : ?Text; // Optional if order is cancelled
  };

  // Service (like a Fiverr gig)
  public type Service = {
    id : Text;
    title : Text;
    description : Text;
    category : Text;
    subcategory : Text;
    startingPrice : Nat; // From the cheapest ServiceTier
    currency : Text;
    deliveryTimeMin : Nat; // Fastest delivery option in days
    status : JobStatus;
    freelancerId : Principal;
    createdAt : Nat;
    updatedAt : Nat;
    tags : [Text];
    attachments : ?[Text]; // Optional portfolio or example files
    tiers : [ServiceTier]; // Multiple tiers (Basic, Standard, Premium)
    contractType : ContractType;
    paymentMethod : PaymentMethod;
    averageRating : ?Float; // Auto-calculated
    totalReviews : Nat;
  };

  public type UnregisteredServiceFormData = {
    title : Text;
    description : Text;
    category : Text;
    subcategory : Text;
    startingPrice : Nat; // From the cheapest ServiceTier
    currency : Text;
    deliveryTimeMin : Nat; // Fastest delivery option in days
    status : JobStatus;
    tags : [Text];
    attachments : ?[Text]; // Optional portfolio or example files
    tiers : [ServiceTier]; // Multiple tiers (Basic, Standard, Premium)
    contractType : ContractType;
    paymentMethod : PaymentMethod;
  };

  public type ServiceUpdateFormData = {
    title : ?Text;
    description : ?Text;
    category : ?Text;
    subcategory : ?Text;
    startingPrice : ?Nat; // From the cheapest ServiceTier
    currency : ?Text;
    deliveryTimeMin : ?Nat; // Fastest delivery option in days
    status : ?JobStatus;
    tags : ?[Text];
    attachments : ?[Text]; // Optional portfolio or example files
    tiers : ?[ServiceTier]; // Multiple tiers (Basic, Standard, Premium)
    contractType : ?ContractType;
    paymentMethod : ?PaymentMethod;
  };

  // Each ServiceTier inside a Service
  public type ServiceTier = {
    id : Text; // Each tier can have an ID (for ordering)
    name : Text; // Basic, Standard, Premium
    description : Text;
    price : Nat; // In smallest unit (e.g., cents)
    deliveryDays : Nat;
    revisions : Nat;
    features : [Text];
  };

  public type UnregisteredServiceTierFormData = {
    name : Text; // Basic, Standard, Premium
    description : Text;
    price : Nat; // In smallest unit (e.g., cents)
    deliveryDays : Nat;
    revisions : Nat;
    features : [Text];
  };

  public type ServiceTierUpdateFormData = {
    name : ?Text; // Basic, Standard, Premium
    description : ?Text;
    price : ?Nat; // In smallest unit (e.g., cents)
    deliveryDays : ?Nat;
    revisions : ?Nat;
    features : ?[Text];
  };

  // JOBS SYSTEM END

  // CLIENT ACTIONS
  // Review type
  public type Review = {
    id : Principal;
    orderId : Text;
    serviceId : Principal;
    reviewerId : Principal;
    recipientId : Principal;
    rating : Nat8; // 1 to 5 stars (validated)
    comment : Text;
    createdAt : Nat; // timestamp (seconds since epoch)
    freelancerResponse : ?Text; // freelancer can respond once
    reviewType : Text; // "client-to-freelancer" or "freelancer-to-client"
  };

  public type Cancellation = {
    orderId : Text;
    cancelledBy : Principal;
    reason : Text;
    cancelledAt : Nat;
  };

  public type Dispute = {
    orderId : Text;
    raisedBy : Principal;
    reason : Text;
    status : Text; // "Open", "Resolved", "Rejected"
    createdAt : Nat;
    resolvedAt : ?Nat;
  };

  public func generateUUID() : async Text {
    let id = Source.Source();

    return UUID.toText(await id.new());
  };

};
