# chat2

A simple telnet app to chat to a server with send and expect

## Install

```
npm install chat2
```

## Example

```javascript

static Chat2 = require('chat2');

static chat = new Chat2('localhost', 110, 5000);
chat.connect()
.then(() => {
  chat.expect(/^\+OK/);
})
.then(() => {
  chat.send('USER cliff');
  chat.exec('PASS password', /^+OK/);
})
.then(response => {
  console.log(response);
  chat.send('QUIT');
  chat.close()
})
```
## Constructor

```javascript
const chat2 = new Chat2(host, port, timeout);
```

#### host

hostname or IP address

#### port

a numeric port, defaulting to 23 if not provided

####timeout 

a timeout in milliseconds, defaulting to no timeout

## Methods

### connect

```javascript
chat2.connect();
```

This sets up the connection to the server, sets encoding
to utf-8 and sets a keepalive.  It mus be called before any other
methods.

### expect

```javascript
chat2.expect(<pattern>)
.then(line => {
  console.log("Received: " + line);
});
```

Called with a regular expression, it returns a promise.  The promise resolves
when the regular expression is matched, returning the full line that
matched.

### send

```javascript
chat2.send(<message>)
.then(() => {
});
```

Sends a message to the server, returning a promise.  The promise
resolves with the message sent.

### exec

```javascript
chat2.exec(<message>, <pattern>)
.then(line => {
  console.log("Received: " + line);
});
```

This calls `send` followed by `expect`.  It returns a promise
which is resolved to the first line that matches the pattern.

Both `expect` and `exec` will reject the promise if the timeout
is reached.  The caught error will be of type `ETIMEDOUT`.

### close

```javascript
chat2.close()
```

This will close the connection cleanly and leave the chat2 instance
ready to be reconnected, if desired.

## Issues

Please let me know of any issues at the
[Github Issues page](https://github.com/CliffS/chat2/issues).
