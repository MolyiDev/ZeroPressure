return table.freeze({
	--==[ First Scene ]==--

	First_Radio_0 = [[We're ready to go. You'll be the first human to reach such depths. Do you want me to explain the procedure one last time?]],

	First_Radio_Tutorial_0 = [[This submarine is prepared for immense depths, but you need to manage it carefully.]],
	First_Radio_Tutorial_1 = [[First, the ocean pressure will cause the <font color="rgb(255, 165, 0)">valves</font> to open slowly. You need to close them immediately.]],
	First_Radio_Tutorial_2 = [[Let me show you. I opened a <font color="rgb(255, 165, 0)">valve</font>. Go close it! It opens to the right, so turn it to the left.]],

	-- After the valve gets closed...
	First_Radio_Tutorial_3 = [[<font color="rgb(50, 255, 50)">Great!</font> Those valves maintain internal pressure, so don't let them vent too much!]],
	First_Radio_Tutorial_4 = [[Second. Sometimes wildlife or rocks will breach the hull and create <font color="rgb(100, 100, 255)">water leaks</font>. Use your <font color="rgb(255, 165, 0)">blowtorch</font> to seal them.]],
	First_Radio_Tutorial_5 = [[I've triggered a small breach. Fix it with the <font color="rgb(255, 165, 0)">blowtorch</font>.]],

	-- After the water leak was fixed...
	First_Radio_Tutorial_6 = [[<font color="rgb(50, 255, 50)">Good.</font> Remember: if the submarine takes on water, your max pressure tolerance <font color="rgb(255, 50, 50)">drops significantly</font>!]],
	First_Radio_Tutorial_7 = [[Third. The <font color="rgb(255, 165, 0)">Main Light</font> can burn out. You'll need to swap it with a fresh one from the <font color="rgb(255, 165, 0)">bulbs box</font>.]],
	First_Radio_Tutorial_8 = [[I broke the Main Light remotely. Grab a spare from the <font color="rgb(255, 165, 0)">box</font> and replace it.]],

	-- After the main light bulb was fixed...
	First_Radio_Tutorial_9 = [[<font color="rgb(50, 255, 50)">Nice.</font> Without that light, you're blind and you won't be able to read your pressure or depth gauges!]],
	First_Radio_Tutorial_10 = [[The <font color="rgb(255, 165, 0)">Engine Light</font> can also break. I've broken it remotely, go ahead and replace it, just like before.]],

	-- After the engine light bulb was fixed...
	First_Radio_Tutorial_11 = [[<font color="rgb(50, 255, 50)">Excellent.</font> If that light dies, you can't monitor the engine temperature.]],
	First_Radio_Tutorial_12 = [[Fourth, speaking of temperature: <font color="rgb(255, 50, 50)">Regulate your speed.</font> If you go too fast and stress the engine, the cabin pressure will drop. Check the <font color="rgb(255, 165, 0)">Engine Light</font> to monitor heat.]],
	First_Radio_Tutorial_13 = [[Use the <font color="rgb(255, 165, 0)">lever</font> to increase velocity and hit max temperature. Since we're shallow, it will heat up fast.]],

	-- When the player put the lever up
	First_Radio_Tutorial_14 = [[Now wait for the engine to overheat. Don't worry, at this depth, zero pressure won't kill you.]],

	-- After the engine gets red temperature
	First_Radio_Tutorial_15 = [[See? The pressure is dropping because the engine is <font color="rgb(255, 50, 50)">overheating</font>. To cool it off, pull the lever all the way down.]],
	First_Radio_Tutorial_16 = [[Now wait for the engine to cool and the pressure to stabilize.]],

	-- After the pressure goes up
	First_Radio_Tutorial_17 = [[<font color="rgb(50, 255, 50)">Perfect.</font> You might think the safest way to descend is keeping the lever all the way down. But keep in mind: <font color="rgb(255, 50, 50)">max pressure declines over time</font>. You need to complete this mission as fast as possible.]],
	First_Radio_Tutorial_18 = [[ Do you want me to explain the procedure again?]],
	-- if the player picks yes then the tutorial starts again
	-- if no then the game starts

	-- After the player has or the player didn't want to see the tutorial.
	First_Radio_1 = [[Just remember: <font color="rgb(255, 50, 50)">do NOT let the pressure hit zero!</font> Starting in <speed val="0.1">3... 2... 1...</speed>]],

	--==[ Second Scene ]==--
	Second_Radio_0 = [[Going down!]],

	-- This scene finishes when the depth gets to 250

	--==[ Third Scene ]==--
	Third_Radio_0 = [[You're halfway there! The external pressure is rising, so expect more <font color="rgb(255, 165, 0)">valves</font> to blow!]],
	Third_Radio_1 = [[I'm detecting large wildlife signatures. Something might bump the submarine. If the hull cracks, <font color="rgb(255, 165, 0)">repair it fast!</font>]],
	-- This scene starts at depth 250 and finishes when the depth gets to 500

	--==[ Fourth Scene ]==--
	-- This scene starts at depth 500

	-- The submarine stops at depth 500
	Fourth_Radio_0 = [[<font color="rgb(50, 255, 50)">You did it!</font> You've reached a depth no human has ever seen!]],
	Fourth_Radio_1 = [[Initiating ascent procedure...]],
	Fourth_Radio_2 = [[<font color="rgb(255, 50, 50)">Wait, there's an error.</font> <speed val="-0.05">@#**(#!)*&@*&*@</speed>]],
	Fourth_Radio_3 = [[<font color="rgb(255, 0, 0)">4R3 Y0U TH3R3?! TH# S!GN4L S33MS T0 B3 CUTT1NG D0WN *&Y#&*@ *(@#&^( @#&*^@*#</font>]],

	-- After the dialogue 3 the submarine gets cut out of the line that was grabbed by some mysterious thing and the communications get cut down.
	-- Then the submarine goes down at immense speeds
	-- The player has to fix everything

	--==[ Fifth Scene ]==--
	-- This scene starts at depth 1000
	-- The submarine touches ground and the camera shakes
	-- The submarine door gets torn down by the pressure and you go out at incredible speeds.
	-- You look back at your submarine while you're going out of the door
	-- You see how a sea creature rushes at your submarine and eats it.
	-- Then you see right to see where the creature did go.
	-- You see nothing
	-- Then you hear something at your back
	-- You turn back
	-- Then the creature rushes at you at incredible speeds with its open mouth.
	-- When the creature gets too close it appears a black screen and the credits roll out with the logo of the game
})
