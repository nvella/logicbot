![logicbot](http://nxk.me/drop/logicbot-banner.png)

Logicbot is a logic processing bot for [Craft](http://www.michaelfogleman.com/craft/). It provides basic logic building blocks that allow players to create both simple and complex machines. Logicbot is currently in Alpha.

Basic usage
-----------

Logicbot deals with **objects** and **channels**. Objects modify channels based on input from other channels. Currently, there are seven different object types;

  - **toggle** 0 inputs, 1 output (Toggles the state of the output channel when block is broken)
  - **lamp** 1 input, 0 outputs (Sets a high light value if the state of the input channel is true)
  - **and** 2 inputs, 1 output (Sets the state of the output channel to true if the state of both input channels are true)
  - **or** 2 inputs, 1 output (Sets the state of the output channel to true if the state of one or both of the input channels are true)
  - **not** 1 input, 1 output (Sets the state of the output channel to the inverse state of the input channel)
  - **xor** 2 inputs, 1 output (Sets the state of the output channel to true *only if the state of one* input channel is true)
  - **indicator** 1 input, 0 outputs (Sets the block the object is placed on to either a green block or a red block depending on the state of the input channel)
  - **door** 1 input, 0 outputs (Removes the block the object is placed on if the state of the input channel is true and restores it if the state of the input channel is false)

To use these objects, place a sign on the block you want to add a logic object to with the contents

  `` `logic OBJECT_TYPE OBJECT_PARAMS ``

where ``OBJECT_TYPE`` is the name of an object type shown above and ``OBJECT_PARAMS`` are the input and output channels, in that order, separated by spaces.

An example for an AND object that changes the state of myOutput if myInput1 and myInput2 are true will look like this:

  `` `logic and myInput1 myInput2 myOutput ``

To delete an object, simply place a sign on it with the contents;

  `` `logic delete ``
  
and to delete both the object and the block the object was added to;
  
  `` `logic delete block``

To retrieve information about an object, place a sign on it with the contents;

  `` `logic info ``

Special, relative channels
--------------------------

The following channels are 'special' channels. They behave differently from user-created channels.

  - **n** (Relative channel - Always points to the object NORTH of the object being created - x+1)
  - **s** (Relative channel - Always points to the object SOUTH of the object being created - x-1)
  - **e** (Relative channel - Always points to the object EAST of the object being created - z+1)
  - **w** (Relative channel - Always points to the object WEST of the object being created - z-1)
  - **u** (Relative channel - Always points to the object ABOVE the object being created - y+1)
  - **d** (Relative channel - Always points to the object BELOW the object being created - y-1)
  - **t** (Always true/on)
  - **f** (Always false/off)
  
Along with these special channels, you may omit the output parameter when creating an object to automatically name the output channel of the object based on the object's co-ordinates. This makes it easy to quickly create relative systems.

Chat commands
-------------

Logicbot will respond to the following strings when said in chat.

  - ``.logicbot debug CHANNEL_NAME`` or ``@Logicbot debug CHANNEL_NAME`` - Returns the state of the channel ``CHANNEL_NAME``.

Todo
----

 *Please see the Github issues page for the todo list.*
