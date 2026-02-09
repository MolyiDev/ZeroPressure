return table.freeze({
	--==[ First Scene ]==--

	First_Radio_0 = [[Good, we are ready to go now. You will be the first human to reach this depth in the ocean. Do you want me to explain to you what to do one last time?]],

	First_Radio_Tutorial_0 = [[This submarine is prepared to get to immense depths in the ocean, but you need to do some things to make it happen.]],
	First_Radio_Tutorial_1 = [[First of all, the pressure exerted by the ocean on the submarine will make the valves start to open. You will need to close them again, but they eventually get opened again.]],
	First_Radio_Tutorial_2 = [[Let me show you, I opened a valve artificially. Go to the valve and close it! The valve opens to the right so you should close it to the left.]],

	-- After the valve gets closed...
	First_Radio_Tutorial_3 = [[Great! These valves release the pressure of the submarine so do not let them release all the pressure!]],
	First_Radio_Tutorial_4 = [[Second, this should not happen, but if it does I have to tell you. If the submarine has water leaks you can use your blowtorch to fix them.]],
	First_Radio_Tutorial_5 = [[Let me show you, I broke a little aperture of the submarine. Fix it with your blowtorch.]],

	-- After the water leak was fixed...
	First_Radio_Tutorial_6 = [[Good! Keep in mind that if the submarine gets water inside, the pressure amount that the submarine can have inside will be limited by the amount of water the submarine has inside!]],
	First_Radio_Tutorial_7 = [[Third, sometimes the light can break, so you need to replace the light bulb with a new one.]],
	First_Radio_Tutorial_8 = [[Let me show you, I breaked the main light bulb artificially. Grab a bulb from the bulbs cage and replace it.]],

	-- After the light bulb was fixed...
	First_Radio_Tutorial_9 = [[Great! If the main bulb breaks, the lack of light will make you blind so you cannot see the pressure or depth. Also, you cannot repair the water leaks and close the valves at the same speed you would do with light!]],
	First_Radio_Tutorial_10 = [[The Engine Light can also break, you can repair it the same way you did with the main light!]],
	First_Radio_Tutorial_11 = [[Also, we have some reports that people go crazy without lights... So please do not be in the darkness too much time.]],
	First_Radio_Tutorial_12 = [[Fourth and most important. You have to regulate your speed. If you go too fast and stress the engine it will start to make the pressure go down. You have to check the engine light to see at what temperature it is.]],
	First_Radio_Tutorial_13 = [[Use the lever there to increase the engine velocity and go to highest temperature. Because we are close to the surface it will heat up faster.]],

	-- When the player put the lever up
	First_Radio_Tutorial_14 = [[Now wait until the engine gets a high temperature, don't worry, nothing will happen in this depth level if you have zero pressure.]],

	-- After the engine gets red temperature
	First_Radio_Tutorial_15 = [[As you can see the pressure it's going down when the engine it's at a high temperature, so you need to regulate the temperature with the speed of the engine. The only way of making the engine cool off it's by putting the lever all the way down.]],
	First_Radio_Tutorial_16 = [[Now lower the velocity and wait for the engine to cool down and the pressure to go up.]],

	-- After the pressure goes up
	First_Radio_Tutorial_17 = [[Good. Do you want me to explain everything again?]],
	-- if the player picks yes then the tutorial starts again
	-- if no then the game starts

	-- After the player has or the player didn't want to see the tutorial.
	First_Radio_1 = [[Just remember, do not let the pressure go to zero! Starting in 3... 2... 1...]],

	--==[ Second Scene ]==--
	Second_Radio_0 = [[Going down!]],

	-- This scene finishes when the depth gets to 250

	--==[ Third Scene ]==--
	Third_Radio_0 = [[You are at the middle of the journey! Because of the depth, the pressure of the ocean on the submarine will be higher so more valves will open up!]],
	Third_Radio_1 = [[Also I'm detecting some wild life down there, it's normal! You can expect some rocks or creatures to bump in the submarine, maybe it cracks, but you can repair it!]],
	-- This scene starts at depth 250 and finishes when the depth gets to 500

	--==[ Fourth Scene ]==--
	-- This scene starts at depth 500

	-- The submarine stops at depth 500
	Fourth_Radio_0 = [[Good! You did it! You reached depths no human has ever reached before!]],
	Fourth_Radio_1 = [[Now we will get you up!]],
	Fourth_Radio_2 = [[Seems that there is an error, @#Y*@(]],
	Fourth_Radio_3 = [[4R3 Y0U TH3R3?! TH# S!GN4L S33MS T0 B3 CUTT1NG D0WN *&Y#&*@ *(@#&^( @#&*^@*#]],

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
