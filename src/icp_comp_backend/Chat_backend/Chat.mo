import Time "mo:base/Time";
import TrieMap "mo:base/TrieMap";
import Text "mo:base/Text";
import Result "mo:base/Result";
import Random "mo:base/Random";
import Array "mo:base/Array";
import Buffer "mo:base/Buffer";
import Principal "mo:base/Principal";
import Source "mo:uuid/Source";
import UUID "mo:uuid/UUID";
import BaseProfile "canister:Profile_backend";
import Util "main";

actor {
    type Message = {
        id : Text;
        content : Text;
        sender : Principal;
        timestamp : Time.Time;
    };

    type Chat = {
        id : Text;
        user1 : Principal;
        user2 : Principal;
        messages : [Text];
    };
    
    let messages = TrieMap.TrieMap<Text, Message>(Text.equal, Text.hash);
    let chats = TrieMap.TrieMap<Text, Chat>(Text.equal, Text.hash);

    public shared query func getChatBetweenTwoUsers(user1 : Principal, user2 : Principal) : async Result.Result<Chat, Text> {
        for (chat in chats.vals()) {
            if (chat.user1 == user1 and chat.user2 == user2) {
                return #ok(chat);
            } else if (chat.user2 == user1 and chat.user1 == user2) {
                return #ok(chat);
            };
        };
        return #err("Not found");
    };

    
    public shared func createChatBetweenTwoUsers(user1: Principal, user2: Principal) : async Result.Result<Chat, Text> {
        let existingChat = await getChatBetweenTwoUsers(user1, user2);
        switch (existingChat) {
            case (#ok(chat)) {
                // Check if the chat already exists
                return #ok(chat);  // Return existing chat
            };
            case (#err(_)) {
                let chatId = await Util.generateUUID();
                let newChat = {
                    id = chatId;
                    user1 = user1;
                    user2 = user2;
                    messages = [];
                };
                chats.put(chatId, newChat);
                return #ok(newChat);
            };
        };
    };

    public shared func getUserChats(user: Principal): async Result.Result<[BaseProfile.BaseProfile], Text> {
        let contactList = Vector.Vector<BaseProfile.BaseProfile>();
        for (chat in chats.vals()) {
            if (chat.user1 == user) {
                let contact = await BaseProfile.getUser(chat.user2);
                switch (contact) {
                    case (?userProfile) {
                        contactList.add(userProfile);
                    };
                    case (null) {
                        return #err("failed fetching user");
                    };
                };
            } else if (chat.user2 == user) {
                let contact = await BaseProfile.getUser(chat.user1);
                switch (contact) {
                    case (?userProfile) {
                        contactList.add(userProfile);
                    };
                    case (null) {
                        return #err("failed fetching user");
                    };
                };
            };
        };
        return #ok(Vector.toArray(contactList));
    };

     public shared func sendMessage(user1: Principal, user2: Principal, content: Text): async Result.Result<Message, Text>{
        try{
            let chat = await getChatBetweenTwoUsers(user1, user2);
            switch(chat) {
                case (#ok(existingChat)){
                    // create a new message
                    let messageId = await Util.generateUUID();
                    let message = {
                        id = messageId;
                        content = content;
                        sender = user1;
                        timestamp = Time.now();
                    };
                    // add the message to the chat and messages map
                    let existingMessages = existingChat.messages;
                    let newMessage = Array.append(existingMessages, [messageId]);
                    let newChat = {
                        chat with
                        messages = newMessage;
                    };
                    chats.put(existingChat.id, newChat);
                    messages.put(messageId, message);
                    return #ok(message);
                };
                case (#err(_)) {
                    return #err("Chat not found");
                };
            }
        } catch (e) {
            return #err("Error sending message: " # e);
        };
     };

    public shared query func getMessage(messageId: Text): async Result.Result<Message, Text> {
        switch(messages.get(messageId)) {
            case (#ok(message)) {
                return #ok(message);
            };
            case (#err(_)) {
                return #err("Message not found");
            };
        };
    };


    public shared func getAllMessagesPaginated(
        user1: Principal,
        user2: Principal,
        page: Nat,
        pageSize: Nat
    ) : async Result.Result<[(Text, Text, Int, Principal, Text)], Text> {
        let allMessages = Buffer.Buffer<(Text, Text, Int, Principal, Text)>(0);
        let chatResult = await getChatBetweenTwoUsers(user1, user2);

        switch (chatResult) {
            case (#ok(chat)) {
                for (messageId in chat.messages.vals()) {
                    let messageResult = await getMessage(messageId);
                    switch (messageResult) {
                        case (#ok(message)) {
                            let senderResult = await BaseProfile.getUser(message.sender);
                            let senderName = switch (senderResult) {
                                case (?userProfile) { userProfile.fullName };
                                case (null) { "Not found!" };
                            };
                            let senderPfp = switch (senderResult) {
                                case (?userProfile) { userProfile.profilePictureUrl };
                                case (null) { "" };
                            };

                            allMessages.add((senderName, message.content, message.timestamp, message.sender, senderPfp));
                        };
                        case (#err(_)) {
                            // Optional: handle error or skip
                        };
                    };
                };
            };
            case (#err(_)) {
                return #err("Chat not found.");
            };
        };

        // Convert buffer to array
        var allMessagesArray = Buffer.toArray(allMessages);

        // Sort messages by timestamp ascending (older messages first)
        allMessagesArray := Array.sort(allMessagesArray, func (a, b) {
            if (a.2 < b.2) { return #greater };
            if (a.2 > b.2) { return #less };
            return #equal;
        });

        // Calculate start and end indices for pagination
        let startIndex = (page - 1) * pageSize;
        let endIndex = startIndex + pageSize;

        if (startIndex >= allMessagesArray.size()) {
            return #ok([]); // No more messages
        };

        let paginatedMessages = Array.slice(allMessagesArray, startIndex, endIndex);

        return #ok(paginatedMessages);
    };




};