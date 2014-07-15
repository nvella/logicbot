logicbot
========

Logicbot is a logic processing bot for Craft. It provides basic logic building blocks that allow players to create both simple and complex machines. Logicbot is currently in Alpha.

Basic usage
-----------

Logicbot deals with **objects** and **channels**. Objects modify channels based on input from other channels. Currently, there are seven different object types;

  - **toggle** 0 inputs, 1 output (Toggles the state of the output channel)
  - **lamp** 1 input, 0 outputs (Sets a high light value if the state of the input channel is true)
  - **and** 2 inputs, 1 output (Sets the state of the output channel to true if the state of both input channels are true)
  - **or** 2 inputs, 1 output (Sets the state of the output channel to true if the state of one or both of the input channels are true)
  - **not** 1 input, 1 output (Sets the state of the output channel to the inverse state of the input channel)
  - **xor** 2 inputs, 1 output(Sets the state of the output channel to true *only if the state of one* input channel is true)
  - **indicator** 1 input, 0 outputs (Sets the block the object is placed on to either a green block or a red block depending on the input channel)

To use these objects, place a sign on a block with the contents

  `` `logic OBJECT_TYPE OBJECT_PARAMS ``

where ``OBJECT_TYPE`` is the name of the object type shown above and ``OBJECT_PARAMS`` are the input and output channels, in that order, separated by spaces.

An example for an AND object that changes the state of myOutput if myInput1 and myInput2 are true will look like this:

  `` `logic and myInput1 myInput2 myOutput ``

To delete an object, simply place a sign on it with the contents;

  `` `logic delete ``

And to retrieve information about an object, place a sign on it with the contents;

  `` `logic info ``

Chat commands
-------------

Logicbot will respond to the following strings when said in chat.

  - ``.logicbot debug CHANNEL_NAME`` Returns the state of the channel CHANNEL_NAME.

.
