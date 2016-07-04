# Getting Started

Diuit provides a simple and powerful API to enable real-time communication in web and mobile apps, or any other Internet connected device. This document provides a guide on how to get you start integrating and interacting with Diuit API.

This document was updated at: 2016-03-31 12:00:00+00

## Prerequisites

*   We do not support Java outside of Android at the moment.
*   A recent version of the Android SDK
*   We support all Android versions since API Level 14 (Android 4.0 & above).



## Installation


You can use Maven to add library in your project.

**Maven**

1.  Navigate to your build.gradle file at the app level (not project level) and ensure that you include the following:

    ```info
    repositories { "maven { "url 'https://dl.bintray.com/duolc/maven' "} "}
    ```

2.  Add `compile 'com.duolc.diuitapi:message:1.1.0'` to the dependencies of your project

        repositories {

            maven {
                url 'https://dl.bintray.com/duolc/maven'
            }
        }

        dependencies {
            // .....
            compile 'com.duolc.diuitapi:message:1.1.0'
        }

3.  In the Android Studio Menu: Tools -> Android -> Sync Project with Gradle Files


* * *

# Authentication

## Quick Start

To authenticate a user, the SDK requires that your backend server application generates an identity token and return it to your application.

To help you generate session token and set up a backend, we provide libraries for the following languages:

1.  [PHP](https://github.com/diuitAPI/diuit.api.php-session-helper)
2.  [JavaScript](https://github.com/diuitAPI/diuit.api.js-session-helper)
3.  [Rails](https://github.com/diuitAPI/diuit.api.rails-session-helper)

You should be able to generate your session token by replacing the ID/Key with your own App ID and App Key obtained from the backend dashboard. If you use other language to develop your backend and you need help, please let us know by sending an email to: [support@diuit.com](mailto:support@diuit.com)

Although the libraries above provide an easy way to obtain session token and complete the authentication process, in the following we also provide a comprehensive step-by-step guide showing you how to authenticate users.

* * *

## Full Authentication Guideline

In order to let a user send and receive messages, you must authenticate them first. Diuit will accept any unique string as a User ID (UIDs, email addresses, phone numbers, usernames, etc), so you can use any new or existing User Management system.

Our messaging server does not directly store your users’ credential. Instead, you will need to have your own account server to manager your users’ credentials and to authenticate them for our messaging server.

After you’ve authenticated your user, you then encrypt a JWT token using the **Encryption Key** obtained from us when you signed up for your account.

The JWT contains a grant telling us which user is allowed access to the messaging server and how long the grant is effective.

Thus, authenticating a user on our messaging server is a 4-step process.

The following description is RESTful by natural, so we do not need to provide SDK APIs for the following calls.

1.  Obtain a random **nonce** from our messaging server through `/1/auth/nonce` API. This nonce is used to prevent replay attack on our messaging server, and prevent the nonce being leaked to a malicious user.

    Note that this step can be performed either by your messaging clients or by your account server, which depends on your system architecture.

2.  With the nonce at hand, you authenticate your client on your account server using whatever method you like.

    If the authentication is successful, your account server will create a JWT authentication token granting the authenticated user who accesses to our messaging server.

3.  You should then call our `/1/auth/login` API using the JWT token as the parameter to obtain a **session token**.

    Note that this step can also be done either on your messaging clients side or on your account server, which depends on your system architecture.

4.  With the session token on hand, the messaging client will use it as the value for the **X-Diuit-Session-Token** header** for all future API calls that requires a specific user session.

    Please note that the **Encryption Key** should be kept private on your account server, and should not be stored on your client devices, unless you have security measures ensuring that the key can be kept secret. (For Android / iOS clients, this is impossible. There are many ways of rooting devices, and storing your encryption key at iOS/Android client devices will make your system vulnerable to attack.)

    If you suspect that your encryption key has been compromised, please reissue a new one on [https://api.diuit.net](https://api.diuit.net) and revoke the old key.

### **1\. Obtaining Authentication Nonce**

The first step of authentication requires you to obtain a random nonce from our messaging server. This nonce is used to prevent replay-attack of the JWT token.

To obtain the nonce from our server, send a GET request to the `/1/auth/nonce` endpoint.

    curl -X GET \
    -H "x-diuit-application-id: ${DIUIT_APP_ID}" \
    -H "x-diuit-app-key: ${DIUIT_APP_KEY}" \
    https://api.diuit.net/1/auth/nonce

The response body is a JSON object containing the `nonce` key.

```info

{ "nonce”: “123asdf123asdf12321adf” }

```

### **2\. Authenticate User On Your Account Server**

The actual user authentication is performed on your own server. Performing any authentication check you’ve implemented to authenticate the user who logs in.

### **3\. Generate JWT Token**

If the user’s identity is verified, your server will generate a JWT token with the following header:

```info

{ “typ: “JWT”, “alg”: “RS256” “cty”: “diuit-auth;v=1” “kid”: ${EncryptionKeyId} }

```

…and with the following claim body:

```info

{ “iss”: ${DIUIT_APP_ID} “sub”: ${UNIQUE_USER_ID} “iat”: ${CURRENT_TIME_IN_ISO8601_FORMAT} “exp”: ${SESSION_EXPIRATION_TIME_IN_ISO8601_FORMAT} “nonce”: ${AUTHENTICATION_NONCE} }

```

… then encrypt the whole thing with your **Encryption Key** obtained when registering for your account.

Note that you can put anything in the “sub” field, which has to be a **string** format, as long as you can co-relate this to the user in your system. Our messaging server will use this field to identify this user.

In the “exp” field, you can specify when this grant will be expired. This field controls for how long the session token generated in the next step will be valid.

Setting this to a relative short value makes the system more secure; leaking a session token will have limited damage. But the drawback is that you will have to re-authenticate your users every so often.

Setting this to a long value can also be useful for Internet of Things (IoT) applications, because you are very confident that the device will not be hacked. You can pre-generate your session token, and set a extremely long expiration date to effectively make the device always authenticated. But in this case, you will have to ensure that the session token is never leaked. (The session token will essentially behaves like a randomly generated password in this case).

In the “kid” field, note to put Encryption Key ID, not **Encryption Key** itself. The JWT header itself is not encrypted, so never put any private data in the JWT header. The JWT header itself is not encrypted, so never put any private data in the JWT header.

### **4\. Login to Messaging Server**

With the JWT token generated, you then POST to the `/1/auth/login` API with the **auth-token** parameter set to the JWT token to obtain a session token for the user.

This step can be done either on the server side or client side. It depends on your own system architecture. But please note that when logging in, you will also need to provide the **deviceId** field to uniquely identify the current device that the user is logging in.

If you are using a web platform, please generate a unique UUID to link with the current web session. (And possibly store the UUID in local storage / cookie).

If your wish to enable push notification on mobile devices, please pass two additional fields: **platform** to indicate what is the push platform to be used (valid values are one of “gcm”, “ios_sandbox”, “ios_production”), and **pushToken** field to indicate the pushToken specific to the push platform.

    curl -X POST \
    -H "x-diuit-application-id: ${DIUIT_APP_ID}" \
    -H "x-diuit-app-key: ${DIUIT_APP_KEY}" \
    -H "Content-Type: application/json" \
    -d '{"authToken":${JWT_TOKEN}, "deviceId": ${DEVICE_ID}, "platform": ${PUSH_PLATFORM}, "pushToken": ${PUSH_TOKEN}' \
    https://api.diuit.net/1/auth/login

If successful, the response will be a JSON object contains the `session` key that should be set in future API calls as `x-diuit-session-token` header to authenticate the user.

```success

{ “session”: “123asdf123asdf12321adf”, “userId”: ${USER_ID} “deviceId”: ${DEVICE_ID} }

```

* * *

# Real-time Communication

Diuit is a powerful API that enables you to add in-app messaging with very little overhead. It can work with any existing User Management system, and includes features such as querying, message delivery, read receipts, conversation metadata, and typing indicators.

## **Authentication for Socket.IO**

For iOS and Android, we have completed the authentication for you in SDK; For Restful, you have to add headers for each request; for direct Socket.IO interface, you will start the real-time messaging session by opening a Socket.IO connection to our server `https://api.diuit.net`.

```java

    // berfore you login with authToken, you have to set APP ID and APP Key first
    public void onCreated(){
       DiuitMessagingAPI.set(String diuitAppId, String diuitAppKey);
       // ...
    }

    //@param authToken, the token of the login device
    DiuitMessagingAPI.loginWithAuthToken(authToken, new DiuitMessagingAPICallback()
    {
        @Override
        public void onSuccess(final JSONObject result)
        {
            // using other APIs
            // ex. register receiving listener
            // DiuitMessagingAPI.registerReceivingMessage(chatReceivingCallback);
        }
        @Override
        public void onFailure(final int code, final JSONObject result)
        {
            // put your code
        }
    });

```

The server should respond with a JSON payload containing your device info to signify the log-in is successfully completed, and then you can start using other APIs.


* * *

## **Listing Chat Room**

```Java

    // In Android, if you have already authenticated the user’s device, you can easily list all the chat room.
    DiuitMessagingAPI.listChats(new DiuitMessagingAPICallback>()
    {
        @Override
        public void onSuccess(final ArrayList chatArrayList)
        {
            // if success, return chatArrayList
        }

        @Override
        public void onFailure(final int code, final JSONObject resultObj)
        {
            // if failure, it will return error code and result
        }
    });

```

Diuit provides convenient and flexible features for users to communicate with each other. It can be real-time one-on-one or group messaging, on-line forum, or review system that we see in modern Internet services. The concept “Chat Room” means the ongoing conversation that a user is currently involving. Diuit API allows you to list and create chat room for users and let your users join or leave a chat room.

* * *

## **Create Chat Room**

Users can start a conversation by creating a chat room. Use the following command to create a chat room and generate a list of people who are in the chat room.

```java

    // @params serialOfUsers: put all the users you want to join into this string array
    // @params meta(optional): you can put attribute of the chat, ex, {'name' : 'this is my new chat room'}
    // @params whiteList(optional): put all users' serials allowed to be joined in this array
    DiuitMessagingAPI.createChat(ArrayList serials, JSONObject meta, ArrayList whiteList, new DiuitMessagingAPICallback()
    {
        @Override
        public void onSuccess(final DiuitChat diuitChat)
        {
            // If success, will return a DiuitChat object
        }

        @Override
        public void onFailure(final int code, final JSONObject resultObj)
        {
            // if failure, it will return error code and result
        }
    });

```

In the **members** field, put the ids of all the people you’d like to include in the chat room as an array. (Note that the ID should be the **sub** field when you are creating your JWT token)

The way of obtaining users’ IDs depends on different applications. For a chatting application, you might have a query API on your own account server to allow your users to query people they want to send messages.

For a chatting application, you might have a query API on your own account server, to allow your user to query their own friends / other contacts they wish to message to.

For an IoT application, instead, you might have a list of pre-written contacts in your firmware.

As a flexible messaging API, Diuit doesn’t assume the types of your application. So you can set up for your own way to interact with our server.

To create a public chat room where everyone can join with no permission, set **whiteList** field to null. To set a private chat room where only invited people can join, set the **whitelist** field to the array of user IDs, who are people invited to join the room.

The **meta** field is a general purpose field for you to store any specific information.

For example, you can store the name of your chat room in this field, a globally shared notes for your chat room, or a base64 encoded small icon. The limit is your imagination.

Again, Diuit doesn’t assume the types of your application. So it is your decision of putting the meta data you’d like to store in this field. Please note, however, that meta field can only store up to 5kb of serialized JSON string.

* * *

## **Join Chat Room**

Once getting invited, your users can join an one-on-one or group conversation. Diuit provides a simple way to do it.

```java

    //@param chatId, the id of the chat room you want the user to join
    DiuitMessagingAPI.joinChat(int chatId, new DiuitMessagingAPICallback()
    {
        @Override
        public void onSuccess(final DiuitChat diuitChat)
        {
            // if success, it will return the DiuitChat object
        }
        @Override
        public void onFailure(final int code, final JSONObject resultObj)
        {
            // if failure, it will return error code and result
        }
    });

```

* * *

## **Leave Chat Room**

Users can also leave a conversation and they will stop receiving messages.

```java

    // Instead of calling DiuitMessagingAPI, you can use the method to let your user leave a chat room
    diuitChat.leaveChat(new DiuitMessagingAPICallback()
    {
        @Override
        public void onFailure(final int code, final JSONObject resultObj)
        {
            // if failure, it will return error code and result
        }
        @Override
        public void onSuccess(final DiuitChat diuitChat)
        {
            // if success, it will return the same DiuitChat object
        }
    });

```

* * *

## **Updating Chat Room Meta Info**

You can update the meta info of a chat room by using this command.

A chat room’s meta info can be used to hold anything application specific to the chat room. Command things to put in it is the name of the chat-room. You can also implement chat-room notes by including the notes info in this key.

```java

    // create new meta for updating the attribute of the chat room
    JSONObject newMeta = new JSONObject();
    newMeta.put("name", newName);

    diuitChat.updateChat(newMeta, new DiuitMessagingAPICallback()
    {
        @Override
        public void onFailure(final int code, final JSONObject resultObj)
        {
            // if failure, it will return error code and result
        }

        @Override
        public void onSuccess(DiuitChat diuitChat)
        {
            // if success, it will return the same DiuitChat object with new meta
        }
    });

```

```warning

Notice!

You have to modify the whole meta as whole; you cannot only update individual keys.

```

* * *

## **Updating Chat Room White List**

In a modern communication platform, the administrator of a chat room has the authority to manage and decide who can be in a chat room. This feature is presented as White List. You can use the following command to update the White List of a chat room.

This UpdateWhiteList function who is allowed to join the chat room. Setting this value to `null` allows everyone to join the chat room; setting this value to `[]` means nobody can join the chat room; setting this value to an array of user IDs will allow a specific group of users to join the chat room.

```java

    // @param serialsOfUsers : all users  you want to set into the white list of this chat room
    // @param diuitChat: the chat which you want to update
    // @Note: Set memberSerials to be null, if you want everyone can join this chat
    diuitChat.updateWhiteList(ArrayList memberSerials, new DiuitMessagingAPICallback()
    {
        @Override
        public void onFailure(final int code, final JSONObject resultObj)
        {
            // if failure, it will return error code and result
        }

        @Override
        public void onSuccess(DiuitChat diuitChat)
        {
            // if success, it will return the same DiuitChat object
        }
    });

```

```warning

#### Notice!

Note that if an user has already joined the chat room, excluding her from the WhiteList doesn’t kick her out from the chat room.

```

* * *

## **Kick User from the Chat Room**

This command is a function for admins to manage members in a chat room. They can remove users from the member list.

Note that kicking a user from the chat room doesn’t change the **WhiteList**. So if the user is in the White List of the chat room, he/she can join back to the room by himself/herself.

```java

    // @param serial : serial of user who you want to kick
    // @param diuitChat : the chat which you want to kick someone from
    diuitChat.kick(String serial, new DiuitMessagingAPICallback()
    {
        @Override
        public void onSuccess(DiuitChat diuitChat)
        {
            // if success, it will return the same DiuitChat object
        }

        @Override
        public void onFailure(final int code, final JSONObject resultObj)
        {
            // if failure, it will return error code and result
        }
    });

```

```info

To completely block a user from joining the chat room, please emit a “chat/whiteList/update” before kicking him out.

```

* * *

## **Receiving Message**

This is a function to add listener to this events to receive real-time messaging from the chat room.

When another user sends a message to the chat room, the listener will receive a “message” event. This message will have the following format:

```info

{   chatId: ${CHATROOM_ID},   data: ${SOME_DATA},   mime: ${DATA_MIME_TYPE},   encoding: ${DATA_ENCOIDNG},   meta: {$USER_SPECIFIC_META_FIELD} }

```

For a text message, the **data** will be the text message itself; MIME type will be **text/plain** and the encoding will be **utf8**.

For rich media messages, the **data** will contain a url pointing to the rich media itself; the **mime** type will be the mime type of the media, and **encoding** will be an **url**.

```java

    // If you want to receive messages , you have to register receiving listener with your object
    // This object could be Activity, Fragment , or any kind of object
    // Once someone sends a message, you would get these in the callback
    DiuitAPI.registerReceivingMessage(DiuitMessagingAPICallback callback)

    // Before you leave the activity, or change the object to be `NULL`, you have to unregister this listener
    DiuitAPI.unregisterReceivingMessage(DiuitMessagingAPICallback callback)

```

* * *

## **Send Text Message**

There are mainly three message types: text, photo, and file. According to the file type, you have to call different API. Use this command to send text message in a chat room.

```java

    // @param text , your text message string
    // @param meta(optional), the meta of the message
    // @param pushTitle(optional), the title of the push notification
    // @param pushMessaging(optional), the message of the push notification
    // @note the default of notification is the text of the message
    diuitChat.sendText(String text, JSONObject meta, String pushTitle, String pushNotification, new DiuitMessagingAPICallback()
    {
        @Override
        public void onSuccess(final DiuitMessage diuitMessage)
        {
            // if success, it will return your DiuitMessage
        }

        @Override
        public void onFailure(final int code, final JSONObject resultObj)
        {
            // if failure, it will return error code and result
        }
    });

```

* * *

## **Send Rich Media Message**

Rich media message refers to photo and file. Use this command to send rich media message in a chat room. You can use those APIs to send photos and files. The mime-type is referred to RFC 2046\. You can retrieve list of allowed mime types [here](http://download.diuit.com/mime-types.json).

> Sending Photos

```java

    // @param bitmap , the bitmap of your photo
    // @param meta(optional), the meta of the message
    // @param userSerial, the user's serial who you want to send to
    // @param pushTitle(optional), the title of the push notification
    // @param pushMessaging(optional), the message of the push notification
    // @note default no notification
    diuitChat.sendImage(Bitmap bitmap, JSONObject meta, String pushTitle, String pushMessaging, new DiuitMessagingAPICallback(){...})

```

> Send files

```java

    // @param file , the File object of your file
    // @param userSerial, the user's serial who you want to send to
    // @param meta(optional), the meta of the message
    // @param pushTitle(optional), the title of the push notification
    // @param pushMessaging(optional), the message of the push notification
    // @note default no notification
    diuitChat.sendFile(File file, JSONObject meta, String pushTitle, String pushMessaging, new DiuitMessagingAPICallback(){...})

```

```warning

#### Notice!

Remember that each message has file size limitation <= 5MB

```

* * *

## **List Historical Messages**

When a new user joins a chat room, you may want her to see the historical messages. This usually happens in the cases of forum or group chat. Use this command to list historic messages.

```java

    // @param before, before the timestamp, UTC+0
    // @param page, start at 0
    diuitChat.listMessagesInChat(Date before, int count, int page, new DiuitMessagingAPICallback>()
    {
        @Override
        public void onSuccess(final ArrayList diuitMessageArrayList)
        {
            // if success, it will return message arraylist
        }
        @Override
        public void onFailure(final int code, final JSONObject resultObj)
        {
            // if failure, it will return error code and result
        }
    });

```

```warning

Response will contain **count** number of message before the timestamp specified in **before** field, skipping over **page * count** number of messages. (In another word, page start at 0)

Messages return in reverse chronological order, with the newest message returned first.

Therefore, in general, you call the API with the current timestamp to obtain all the latest messages, and required, call the API with an older timestamp to obtain older messages.

```

* * *

## **Mark Message as being Read**

In modern ways of communication, user would like to know if her message is read by other users. Use this command to mark a message as read. Note that it is not necessary to use this command. In some cases it may be not appropriate to have this feature. It’s perfectly fine if you want to implement a chat system without read indications.

```java

    // @param message, the message that you want to mark as read
    diuitMessage.markAsRead(new DiuitMessagingAPICallback()
    {
        @Override
        public void onSuccess(final DiuitMessage resultObj)
        {
            // if success, it will return the same diuitMessage object
        }
        @Override
        public void onFailure(final int code, final JSONObject resultObj)
        {
            // if failure, it will return error code and result
        }
    });

```

* * *

## **System Messages**

Our messaging system will automatically send **system messages** to chat rooms if some interesting events happen.

There are currently 5 kinds of system messages.

### **User Left Chat Room**

When a user left a chat room, all members of the chat room will receive a message with type **user.left** and a single key **userId** signifying which user has left the chat room.

### **User Joined Chat Room**

When a user joined a chat room, all members of the chat room will receive a message with type **user.joined** and a single key **userId** signifying which user has joined the chat room.

### **White List Updated**

When a member of the chat room update the White List, all members in the chat room will receive a message with type **whiteList.updated**, and a single key **whiteList** providing the latest state of the white list.

### **User being Kicked Out**

When a user is kicked from a chat room, all members in the chat room will receive a message with type **user.kicked**, and a single key **userId** signifying which user was kicked from the chat room.

### **Chat Room Meta Update**

When a member in the chat room updates the chat room’s meta field, all members of the chat room will receive a message with type **meta.updated**, and a single key **meta** providing the latest state of the chat room’s meta field.

* * *

# Direct Message

In our standard API, we manage basic in-app messaging features for most of the cases. In some cases, however, like when you want to enable one-on-one chat or user-block features, those basic in-app messaging features won’t be enough. Therefore, we've built DirectMessage for these scenarios.

* * *

## **Creating Direct Chat Room**

Users can start an one-on-one conversation by creating a Direct Chat Room, which can be created by using following commands.

```java

    // @params userSerial: put the user you want to send direct message to
    // @params meta(optional): the meta of the chat
    public static void createDirectChat(String serial, final JSONObject meta, final DiuitMessagingAPICallback callback)
    {
        @Override
        public void onSuccess(final DiuitChat diuitChat)
        {
            // If success, will return a DiuitChat object
        }

        @Override
        public void onFailure(final int code, final JSONObject resultObj)
        {
            // if failure, it will return error code and result
        }
    });

```

```warning

Direct Chat Room does not support features like "join", "kick", "leave", and "updating whiteList".

```

* * *

## **Advanced Listing Chat Room**

By default, listing chat will return all chats. You can get a list of direct chats or a list of group chats by [ChatType](#chat-type). As the following command.

```java

    DiuitMessagingAPI.listChats(DiuitChatType chatType, final DiuitMessagingAPICallback> callback) {
        @Override
        public void onSuccess(final ArrayList chatArrayList)
        {
            // if success, return chatArrayList
        }

        @Override
        public void onFailure(final int code, final JSONObject resultObj)
        {
            // if failure, it will return error code and result
        }
    });

```

* * *

## **Send Direct Text Message**

As [Send Text Message](#send-text-message), user can directly send text messages to the other one by that user's serial. If the user doesn’t have their Direct Chat yet, we will create one for them. In other words, if the user has already created his Direct Chat, we will send the text message into this chat.

```java

    // @param userSerial , the user who you want to send to
    // @param text , your text message string
    // @param meta(optional), the meta of the message
    // @param pushTitle(optional), the title of the push notification
    // @param pushMessaging(optional), the message of the push notification
    // @note the default of notification is the text of the message
    DiuitMessagingAPI.sendDirectText(String userSerial,String text,JSONObject meta, String pushTitle, String pushMessage, DiuitMessagingAPICallback callback)
    {
        @Override
        public void onSuccess(DiuitMessage diuitMessage)
        {
            // if success, it will return your DiuitMessage
        }

        @Override
        public void onFailure(int code, JSONObject resultObj)
        {
            // if failure, it will return error code and result
        }
    });

```

* * *

## **Send Direct Media Message**

Users can also directly send rich media text to the other user.

> Send photos

```java

    // @param bitmap , the bitmap of your photo
    // @param meta(optional), the meta of the message
    // @param userSerial, the user's serial who you want to send to
    // @param pushTitle(optional), the title of the push notification
    // @param pushMessaging(optional), the message of the push notification
    // @note default no notification
    DiuitMessagingAPI.sendDirectImage(String serial, Bitmap bitmap, JSONObject meta, String pushTitle, String pushMessaging, new DiuitMessagingAPICallback(){...})

```

> Send files

```java

    // @param file , the File object of your file
    // @param userSerial, the user's serial who you want to send to
    // @param meta(optional), the meta of the message
    // @param pushTitle(optional), the title of the push notification
    // @param pushMessaging(optional), the message of the push notification
    // @note default no notification
    DiuitMessagingAPI.sendDirctFile(String serial, File file, JSONObject meta, String pushTitle, String pushMessaging, new DiuitMessagingAPICallback(){...})

```

```warning

#### Notice!

Remember that each message has file size limitation <= 5MB

```

* * *

## **Block Users**

This feature allows your user to block the other one. The former user won’t receive any message from the later one. At the server side, we will respond an error message when the blocked user sends a message to the former one. But you can customize the message and UI you’d like to show in your app.

```java

    // To block a user
    DiuitMessagingAPI.block(String userSerial, new DiuitMessagingAPICallback {
        @Override
        public void onSuccess(final JSONObject result)
        {

        }
        @Override
        public void onFailure(final int code, final JSONObject result)
        {

        }
    });

```

> Beside, you can unblock users by the following command.

```java

    // To unblock a user
    DiuitMessagingAPI.unblock(String userSerial, new DiuitMessagingAPICallback {
        @Override
        public void onSuccess(final JSONObject result)
        {

        }
        @Override
        public void onFailure(final int code, final JSONObject result)
        {

        }
    });

```

* * *

# Announcement

Announcement allows you to create a new event and send it to a list of users in the same channel or all users of your application. Announcement can only support HTTPS-based APIs and every API request needs a JWT token.

## **Authentication**

Note that new announcement has to be created from the server side, which means we haven't yet provided a backend GUI for you to create and send announcement. If you need any help, please send us email to [support@diuit.com](mailto:support@diuit.com)

All announcement calls must be signed with an jwt token. Before creating a new announcement, you need to create a **JWT token** as the header value.

Generating a JWT token as the following header:

```info

{ “typ: “JWT”, “alg”: “RS256” “cty”: “diuit-auth;v=1” “kid”: ${EncryptionKeyId} }

```

...and with the following claim body:

```info

{ “iss”: ${DIUIT_APP_ID} “sub”: '__admin__' “iat”: ${CURRENT_TIME_IN_ISO8601_FORMAT} “exp”: ${SESSION_EXPIRATION_TIME_IN_ISO8601_FORMAT} }

```

...and then encrypt the entire list with your Encryption Key obtained at DIuit backend dashboard. For more information about JWT token, please refer to [Authenticating User](#authenticating-user)

* * *

## Using Channels

The simplest way to send announcements is using Channels, which allows you to use a `publisher-and-subscriber` model to send announcement to the users of your application. You can POST RESTful API to create a new channel and directly send announcement to your users once they subscribe one or more channels. For more information about Channels, please refer to [Channel](#channel).

* * *

## Create Announcement

Use the following command to create a new announcement

    # To create a new annoucement,
    # @param title(required), the title of the announcement
    # @param type(optional), the type of the announcement
    # @param keywords(optional), you can search announcements by keywords
    # @param body(required), the date of the announcement
    # @param channelId(required), the id of the channel which you want to send to
    # @param meta(optional), the meta of the announcement
    # @param sendNotification(optional), if true, users in channel will receive push notification
    curl -X POST \
    -H "Authorization: Basic ${YOUR_JWT_TOKEN}" \
    -H "x-diuit-application-id: ${DIUIT_APP_ID}" \
    -H "x-diuit-app-key: ${DIUIT_APP_KEY}" \
    -H "Content-Type: application/json" \
    -d '{ "title": ${TITLE}, "type": ${TYPE}, "keywords": ${KEYWORDS}, "body": ${ANNOUNCE_BODY}, "channelId": {$CHANNEL_ID}, "meta": {${META}}, "sendNotification": true'} \
    https://api.diuit.net/1/announcements

If setting `sendNotification` to be `true`, the values of title and body will be displayed in notification. The `meta` field is a general purpose field for you to store any specific information. The value of `keywords` will help you to search announcements conveniently.

```warning

Title and body should be less than 255 bytes.

```

* * *

## Update Announcement

Diuit Messaging API also provides flexible features for you to modify. Use the following command to update the announcement

    # To update a annoucement,
    # @param title, the title of the announcement
    # @param type, the type of the announcement
    # @param keywords, you can search announcements by keywords
    # @param body, the date of the announcement
    # @param meta, the meta of the announcement
    curl -X PATCH \
    -H "Authorization: Basic ${YOUR_JWT_TOKEN}" \
    -H "x-diuit-application-id: ${DIUIT_APP_ID}" \
    -H "x-diuit-app-key: ${DIUIT_APP_KEY}" \
    -H "Content-Type: application/json" \
    -d '{ "title": ${TITLE}, "type": ${TYPE}, "keywords": ${KEYWORDS}, "body": ${ANNOUNCE_BODY}, "meta": {${META}}} \
    https://api.diuit.net/1/announcements/{:announcement_id}

* * *

## List Announcement

```warning

We provide you a group of functions to manage your announcement. You can easily count the number of announcement by multiple **page** and **count** (page starts at 0). You can also manage the order of the announcement by using **isAscending** or **orderBy**, and search specific announcement by keywords.

```

    # param orderBy(optional), only support two types: 'createdAt' and 'updatedAt'
    # param isAscending(optional), is a boolean value 'true' or 'false'
    # param keywords(optional), the keywords for searching
    curl -X GET \
    -H "Authorization: Basic ${YOUR_JWT_TOKEN}" \
    -H "x-diuit-application-id: ${DIUIT_APP_ID}" \
    -H "x-diuit-app-key: ${DIUIT_APP_KEY}" \
    -H "Content-Type: application/json" \
    -d "page=${PAGE_NUMBER_TO_GET}&count=${ANNOUNCEMENT_PER_PAGE}&isAscending=${IS_ASCENDING}&orderBy=${ORDER_BY}&keywords=${KEYWORDS} \
    https://api.diuit.net/1/announcements/

* * *

## Delete Announcement

    curl -X DELETE \
    -H "Authorization: Basic ${YOUR_JWT_TOKEN}" \
    -H "x-diuit-application-id: ${DIUIT_APP_ID}" \
    -H "x-diuit-app-key: ${DIUIT_APP_KEY}" \
    -H "Content-Type: application/json" \
    https://api.diuit.net/1/announcements/{:announcement_id}

* * *

# Channel

Each channel has three properties: **title**, **targetPlatforms**, and **targetUserSerials**. The **targetUserSerials** is an array of subscribers’ serials that allow a specific group of users to receive the announcement. Setting this value to `null` will let all the users to receive the announcement; setting this value to `[]` means nobody subscribe to this channel. And the **targetPlatforms** is also an array of platforms which is supported by `gcm`, `ios_sandbox`, and `ios_production`. Setting this value to `null` will let all the platforms to receive the announcement; setting this value to `[]` means no device subscribe to this channel. **targetPlatforms** is also an array of platforms which supports `gcm`, `ios_sandbox`, and `ios_production`. Setting this value to null will let all the platforms receive announcement; setting this value to [] means there is no device subscribes to this channel.

* * *

## Create Channel

Use the following command to create a new channel

    # To create a new channel,
    # @param title(required), the title of the channel
    # @param targetPlatforms(optional), put the platform allowed to receive push notification in this array
    # @param targetUserSerials(required), put all users' serials allowed to be joined in this array
    curl -X POST \
    -H "Authorization: Basic ${YOUR_JWT_TOKEN}" \
    -H "x-diuit-application-id: ${DIUIT_APP_ID}" \
    -H "x-diuit-app-key: ${DIUIT_APP_KEY}" \
    -H "Content-Type: application/json" \
    -d '{ "title": ${TITLE}, "targetPlatforms": [ ${PLATFORM1}, ${PLATFORM2}], "targetUserSerials": [${USER_SERIAL1}, ${USER_SERIAL2}]} \
    https://api.diuit.net/1/channels

* * *

## Update Channel

    # To update a channel,
    # @param title, the title of the channel
    # @param targetPlatforms, put the platform allowed to receive push notification in this array
    # @param targetUserSerials, put all users' serials allowed to be joined in this array
    curl -X PATCH \
    -H "Authorization: Basic ${YOUR_JWT_TOKEN}" \
    -H "x-diuit-application-id: ${DIUIT_APP_ID}" \
    -H "x-diuit-app-key: ${DIUIT_APP_KEY}" \
    -H "Content-Type: application/json" \
    -d '{ "title": ${TITLE}, "targetPlatforms": [ ${PLATFORM1}, ${PLATFOR2}], "targetUserSerials": [${USER_SERIAL1}, ${USER_SERIAL2}]} \
    https://api.diuit.net/1/channels/{:channel_id}

* * *

## List Channel

    # To list channels,
    curl -X GET \
    -H "Authorization: Basic ${YOUR_JWT_TOKEN}" \
    -H "x-diuit-application-id: ${DIUIT_APP_ID}" \
    -H "x-diuit-app-key: ${DIUIT_APP_KEY}" \
    -H "Content-Type: application/json" \
    https://api.diuit.net/1/channels

* * *

## Delete Channel

    # To delete a channel,
    curl -X DELETE \
    -H "Authorization: Basic ${YOUR_JWT_TOKEN}" \
    -H "x-diuit-application-id: ${DIUIT_APP_ID}" \
    -H "x-diuit-app-key: ${DIUIT_APP_KEY}" \
    -H "Content-Type: application/json" \
    https://api.diuit.net/1/channels/{:channel_id}

* * *

# Push Notification

This guideline provides you with a step-by-step guide to configure your mobile application for push notifications. Push notification let your application notify a user of new messages or events, even when the user is not actively using your app.

## **Prerequisites**

```java

Support Diuit 1.0.0 & above

### Set up a Google Cloud Messaging (GCM) Client ID

To send push notifications to an Android app, you need to complete these following steps:

*   Get a Server API key & Sender ID from Google Console Developer
*   Call DiuitMessagingAPI after authenticating session token

### Creating a Google Developers Console project and client ID

*   - Go to [Google Developer Console](https://console.developers.google.com)
*   - From the project drop-down, select an existing project or create a new one by selecting Create a new project.
*   [![](../images/gcm-step-1.png)](../images/gcm-step-1.png)
*   - In the slidebar under "API Manager", select Credentials, and then select the **Credentials** tab.
*   - Select the **New credentials** drop-dwon list, and choose **API Key**
*   [![](../images/gcm-step-2.png)](../images/gcm-step-2.png)
*   - Create a server API key and copy your API key, which should be like **AIz...**

### Enable Google Cloud Messaging Service

*   - After creating a server API key, in API Manager Page, click Overview
*   [![](../images/gcm-step-3.png)](../images/gcm-step-3.png)
*   - Find Google Cloud Messaging and enable this service
*   [![](../images/gcm-step-4.png)](../images/gcm-step-4.png)

### Find your project number

*   - Click **Google Developers Console** at upper right and select **Dashboard**
*   - From the ID drop-down, you will see the project ID and the project number
*   [![](../images/gcm-step-5.png)](../images/gcm-step-5.png)

### Go to Diuit Dashboard and update your Android GCM certification

*   - Go to [Diuit Developer Dashboard](http://developer.diuit.com/dashboard)
*   - From the Notification drop-down, select Android.
*   [![](../images/gcm-step-6.png)](../images/gcm-step-6.png)
*   - Copy and paste your GCM API key and your Sender ID, and then click **Submit**
*   - Should be all set. If you have any problem regarding setting up Push Notification, please contact us at Slack

### Setup Diuit Messaging API in your App

After `DiuitMessagingAPI.loginWithAuth` succeeds, call `DiuitMessagingAPI.registerPushNotificationService()` and pass the project number as a parameter. For Android, we have completed GCM registration and we can upload the new push token to our server in `registerPushNotificationService` this function.

*   - Remember register your service in manifest

    <service android:name="./PATH/.SERVICE" android:exported="false" \>
      <intent-filter>
          <action android:name="com.google.android.c2dm.intent.RECEIVE" />
      </intent-filter>
    </service>

```

* * *

## **Sending with Notification**

Diuit Messaging API will help you send out push notification along with your messages. Every text message will be sent with a push notification, and you can customarise the push title and body you’d like to show to your users. On iOS/Android devices, your application's icon and a message will appear in the status bar when the user receives a push notification. A receiver must enable push notification in the chat room to receive related notifications.(When you create or join a chatroom, push notifcation of the chat room is enabled in default)



> Enable/Disable push notification in a chat room

```Java

    // To enable receiving notifications,
    DiuitChat.enablePushNotification(new DiuitMessagingAPICallback {
        @Override
        public void onSuccess(final JSONObject result)
        {

        }
        @Override
        public void onFailure(final int code, final JSONObject result)
        {

        }
    });

    // To disable push notifications,
    DiuitChat.disablePushNotification(new DiuitMessagingAPICallback {
        @Override
        public void onSuccess(final JSONObject result)
        {

        }
        @Override
        public void onFailure(final int code, final JSONObject result)
        {

        }
    });

```

> Customize your notification

```java

    // @param text , your text message string
    // @param meta(optional), the meta of the message
    // @param pushTitle(optional), the title of the push notification
    // @param pushMessaging(optional), the message of the push notification
    // @note the default of notification is the text of the message
    diuitChat.sendText(String text, JSONObject meta, String pushTitle, String pushNotification, new DiuitMessagingAPICallback(){/*put your code*/})

```

> Customize your broadcast receiver(Android Only)

```Java

    //In your app you can extends `DiuitPushBroadcastService`
    //Overwrite showNotification(String title, String message, JSONObject payload).
    //Here you can customize your push notification
    public class ExampleBroadcastService extends DiuitPushBroadcastService
    {
       @Override
       public void showNotification(String title, String message, JSONObject payload)
       {
           // put your code
       }
    }

```
Remember register your service in manifest

    <service android:name="./PATH/.SERVICE" android:exported="false" \>
    <intent-filter>
    <action android:name="com.google.android.c2dm.intent.RECEIVE" />
    </intent-filter>
    </service>


* * *

# Class

Diuit Messaging API provides the easiest way for you to manage your users and enables in-app messaging in your app, allowing your users to communicate with each other in your app.

## **Messaging API**

To login with device auth token.

```java

    //@param `authToken`, the auth of the device which is provided by client server
    //@param `callback`, after logging in, Diuit server will return a JSONObject which contains the information about the device itself
    static void loginWithAuthToken(DiuitMessagingAPICallback callback, String authToken)

```

* * *

## **User**

After calling this function `loginWithAuthToken`, Diuit server will return the current`DiuitUser`, which contains the user’s ID, serialNumber and all devices she owns.

```java

    //@param Integer id, the user's id
    private int id;
    //@param String serial, the user's serialNumber
    private String serial;
    //@param List devicesList, all devices which the user owns
    private List deviceList;

```

* * *

## **Device**

After calling this function `loginWithAuthToken`, Diuit server will return the current `DiuitDevice`, which contains the information of the device, including device ID, serial number, platform, and status.

```java

    //@param Integer id, the id of the device
    private int id;
    //@param String serial, the serialNumber of the device
    private String serial;
    //@param String platform, the platform of the device
    private String platform;
    //@param String authToken, the auth token of the device
    private String authToken;

```

* * *

## **Chat**

The `Chat` class models a chat room between two or more participants. A chat room is an on-going stream of messages (modeled by the `Message` class) synchronized among all participants.

```java

    //@param Integer id, the id of the chat room
    private int id;
    //@param List memberSerials, all memeber's serialNumber in the chat room
    private List memberSerials;
    //@param JSONObject meta, the meta of the chat room
    private JSONObject meta;
    //@param DiuitMessage lastMessage, the last message in the chat room, you have to update by your self
    private DiuitMessage lastDiuitMessage;
    //@param List whitList, the whitList of the chat room
    private List whiteList;
    //@param DiuitChatType type, the type of the chat room
    private DiuitChatType type;
    //@param boolean pushEnabled, enable push notification or not
    private boolean pushEnabled;
    //@param boolean isBlockedByMe, only support direct type
    private boolean isBlockedByMe;

    // By calling this function, the serial would be added into memberSerials
    void addMember(String serial)
    // By calling this function, the serial would be removed from the memberSerials
    void removeMember(String serial)
    // By calling this function, you can chage the value of the parameter 'isBlockedByMe'
    void setIsBlockedByMe(boolean isBlockedByMe)

```

* * *

## **ChatType**

The `ChatType` module is an enumeration class that can be used to define unique sets of the type of the chat room. There are two types of chat: group and direct

```java

    enum DiuitChatType {
        GROUP, DIRECT
    }

```

* * *

## **Message**

The `Message` class represents a message in a chat room (modeled by the `Chat` class) between two or more participants.

```java

    //@param Integer id, the id of the message
    private int id;
    //@param String mime, the mime of the message
    private String mime;
    //@param String encoding, the encoding of the message
    private String encoding;
    //@param String data, the data of the message
    private String data;
    //@param JSONObject meta, the meta of the message
    private JSONObject meta;
    //@param Date createAt, the created time of the message
    private Date createdAt;
    //@param DiuitChat diuitChat, the message in the chat room
    private DiuitChat diuitChat;
    //@param DiuitUser sender, the sender of the message
    private DiuitUser sender;
    //@param List reads, all readers' serialNumber
    private List reads;

```

* * *

## **Callback**

Callback attaches to each Diuit API function. Depending on different types of function, callback will return different types of result. As an event happenes, for example - when a user joins a chat room, a message being sent, or a messages marked as read - DiuitAPI will receive an event notice on the main thread by default. And then the callback, running in the background, responses the result in the background thread.

* * *

# Errors

Diuit uses conventional HTTP response codes to indicate the success or failure of an API request. In the following we list a table of error codes we’ll return on our platform:


| Tables        | Are           | Cool  |
| ------------- |:-------------:| -----:|
| col 3 is      | right-aligned | $1600 |
| col 2 is      | centered      |   $12 |
| zebra stripes | are neat      |    $1 |


* * *

# Change Logs

The latest version is 008

[Click here](https://gist.github.com/diuitAPI/5e9a297c9afd74f259e8) for the complete release note

* * *
