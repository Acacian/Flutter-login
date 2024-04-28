const express = require('express');

const app = express();

mongoose
  .connect('mongodb+srv://testuser1:jZGk5M0wcYdyBLPm@doha.xxt8fwd.mongodb.net/messages?retryWrites=true' ,
    { useNewUrlParser : true },
  )
  .then(result => {
    const server = app.listen(8080);
    const io = require('./socket').init(server);
    io.on('connection', socket => {
    });
  })
  .catch(err => console.log(err));
