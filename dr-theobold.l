## dr-theobold.l - a text-based adventure game
## Copyright (C) 2017  Christopher Howard

## This program is free software: you can redistribute it and/or modify
## it under the terms of the GNU General Public License as published by
## the Free Software Foundation, either version 3 of the License, or
## (at your option) any later version.

## This program is distributed in the hope that it will be useful,
## but WITHOUT ANY WARRANTY; without even the implied warranty of
## MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
## GNU General Public License for more details.

## You should have received a copy of the GNU General Public License
## along with this program.  If not, see <http://www.gnu.org/licenses/>.

(load "tree.l")

(de prinll @ (prog
                (apply 'prinl (rest))
                (prinl)))

(de world ARGLST
   (setq World (aa-insert "rooms" NIL NIL))
   (run ARGLST)
   World )

(de save-world (Filename)
   (let Result
      (catch '(NIL)
         (out Filename
            (println World) )
         (prinll "Game progress saved.")
         'Complete)
      (unless (= Result 'Complete)
         (prinll Result) ) ) )

(de load-world (Filename)
   (let Result
      (catch '(NIL)
         (in Filename
            (setq World (read)) )
         (prinll "Saved game loaded.")
         'Complete )
      (if (<> Result 'Complete)
         (prog
            (prinll Result)
            (prinll "Could not find file \"theobold.sav\" in current directory.") )
         (look-at-room (location)) ) ) )

(de location @
   (if (not (arg 1))
      (aa-search-val World "location")
      (setq World (aa-insert "location" (next) World)) ) )

(de rooms ()
   (aa-search-val World "rooms") )

(de room ARGLST
   (if (not (car ARGLST))
      (quit "func `room' missing argument")
      (let (Room ())
         (run (cdr ARGLST))
         (setq World
            (aa-insert
               "rooms"
               (aa-insert (car ARGLST) Room (rooms)) World ) ) ) ) )

(de room-long-description (Description)
   (setq Room (aa-insert "long-description" Description Room)) )

(de room-command (Lst Fn)
   (setq Room (aa-insert "room-commands"
                 (aa-insert Lst Fn
                    (aa-search-val Room "room-commands") )
                 Room ) ) )
   
(de room-exit (Direction Fn)
   (setq Room (aa-insert "room-exits"
                 (aa-insert Direction Fn
                    (aa-search-val Room "room-exits") )
                 Room ) ) )

(de get-room (RoomID)
   (aa-search-val (rooms) RoomID) )

(de print-exits (RoomID)
   (let (Exit-Str
         (glue ", "
            (aa-keys-to-list
               (aa-search-val
                  (get-room RoomID) "room-exits" ) ) ) )
      (when Exit-Str
         (prinll "Exits: " Exit-Str))))

(de look-at-room (RoomID)
   (prinll (aa-search-val (get-room RoomID) "long-description"))
   (print-exits RoomID))

(de enter-room (RoomID)
   (location RoomID)
   (look-at-room RoomID) )

(de c-loop X
   (let (continue '(() (throw 'CONTINUE NIL))
         break '(() (throw 'BREAK NIL)))
      (catch 'BREAK
         (loop
            (catch 'CONTINUE
               (run X) ) ) ) ) )

(de print-help ()
   (prinll "Common commands are...\n\n"
      "help, quit, save, load, go <exit>, look, look at <item>, search <item>, \
       use <item>, break <item>, drop <item>, put <item> in <item>, speak <word>." ) )

(de print-warranty ()
   (prinll
      "This program is distributed in the hope that it will be useful,\n"
      "but WITHOUT ANY WARRANTY; without even the implied warranty of\n"
      "MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the\n"
      "GNU General Public License for more details." ) )

(de print-license ()
   (prinll
      "This program is free software: you can redistribute it and/or modify\n"
      "it under the terms of the GNU General Public License as published by\n"
      "the Free Software Foundation, either version 3 of the License, or\n"
      "(at your option) any later version.\n\n"
      "You should have received a copy of the GNU General Public License\n"
      "along with this program.  If not, see <http://www.gnu.org/licenses/>."))

(de print-inventory ()
   (let (inventory-lst
         (sort
            (mapcar 'car
               (aa-to-list
                  (aa-search-val World "inventory") ) ) ) )
      (if (not inventory-lst)
         (prinll "You are not carrying anything.")
         (prog
            (prinll "Your are carrying the following items:")
            (prinll (glue " " inventory-lst)) ) ) ) )

(de handle-unhandled-cmd (Cmd)
   (cond
      ((= (head 2 Cmd) '("look" "at"))
       (prinll "You notice nothing of interest.") )
      ((= Cmd '("search"))
       (prinll "You must search some thing, like \"search cabinet\".") )
      ((= (car Cmd) "search")
       (prinll "You find nothing of interest.") )
      ((= (car Cmd) "put")
       (prinll "You cannot do that.") )
      ((or (= (car Cmd) "use")
          (= (car Cmd) "break")
          (= (car Cmd) "drop")
          (= (car Cmd) "take") )
       (prinll "You do not see any value in doing that.") )
      (T
         (prinll "Nothing happens.") ) ) )

(de read-loop ()
   (c-loop
      (prin "> ")
      (flush)
      (let (Cmd (str (line T)))
         (prinl "")

         (when (= Cmd '("help"))
            (prog (print-help) (continue)))

         (when (= Cmd '("warranty"))
            (prog (print-warranty) (continue)))
         
         (when (= Cmd '("license"))
            (prog (print-license) (continue)))
         
         (when (= Cmd '("look"))
            (prog (look-at-room (location)) (continue)) )
         
         (when (or (= Cmd '("quit")) (= Cmd '("bye")))
            (prog (prinll "Goodbye!") (bye)) )

         (when (or (= Cmd '("inventory")) (= Cmd '("show" "inventory")))
            (prog (print-inventory) (continue)) )

         (when (= Cmd '("save"))
            (save-world "theobold.sav")
            (continue) )
         
         (when (= Cmd '("load"))
            (load-world "theobold.sav")
            (continue) )
         
         (let (RoomCmd
               (aa-search-val
                  (aa-search-val
                     (get-room (location))
                     "room-commands" ) Cmd ) )
            (when RoomCmd
               (prog (RoomCmd) (continue)) ) )
         
         (if (= (car Cmd) "go")
            (let (ExitCmd
                  (aa-search-val
                     (aa-search-val
                        (get-room (location))
                        "room-exits" ) (cadr Cmd) ) )
               (if ExitCmd
                  (prog (ExitCmd) (continue))
                  (prog (prinll "You cannot go that direction.") (continue)) ) ) )
         
         (handle-unhandled-cmd Cmd) ) ) )

(de set-world-var (Name Val)
   (setq World (aa-insert "variables"
                  (aa-insert Name Val
                     (aa-search-val World "variables") ) World ) ) )

(de read-world-var (Name)
   (aa-search-val (aa-search-val World "variables") Name) )

(de add-to-inventory (ItemName ItemData)
   (setq World (aa-insert "inventory"
                  (aa-insert ItemName ItemData
                     (aa-search-val World "inventory") ) World ) ) )

(de remove-from-inventory (ItemName)
   (setq World (aa-insert "inventory"
                  (aa-delete ItemName
                     (aa-search-val World "inventory") ) World ) ) )

(de inventory-contains? (ItemName)
   (car (aa-search (aa-search-val World "inventory") ItemName)) )

(de get-inventory-data (ItemName)
   (aa-search-val (aa-search-val World "inventory") ItemName) )

(de use-threshold-keypad ()
   (prin "Enter a five digit code: ") (flush)
   (let (Input (car (str (line T))))
      (if (or (not (num? Input))
             (< Input 0) (> Input 99999) )
         (prinll "Five digits, please.")
         (if (= Input 31415)
            (prog (prinll "\nYou hear a clicking sound.")
               (set-world-var "threshold-door-unlocked" T))
            (prinll "\nYou input the code but nothing happens.") ) ) ) )

(de letter? (C) (and (str? C)
                   (or (and (>= C "A") (<= C "Z"))
                      (and (>= C "a") (<= C "z")) ) ) )

(de cryptogram-encrypt (Message SubsTree)
   (let (SubFn
         '((C) (if (not (letter? C))
                  C
                  (let (UC (uppc C))
                     (if (aa-search-val SubsTree UC)
                        @
                        "_" ) ) ) ) )
      (glue "" (mapcar 'SubFn (chop Message))) ) )

(de space-out (Str)
   (glue " " (chop Str)) )

(de use-crypto-tablet ()
   (prinll "The tablet displays a cryptogram:")
   (prinll "Enter a letter, a space, and then the letter you wish to \
            substitute for it. If you wish to take a break, enter \"done\".")
   (let (EncMessage
         "GPB J YZVPNB OXANUT YE RNDEUB IJABEO, GPB OGBPNAA, GPB TEUUX:\n\
          TEV IDGY LGP YDN OGP BE YDGY LEONA GTYNV YDN HJPF?\n\
          NMNP YDGY IDJLD DGA RNNP GUVNGBX BEPN."
         DecMessage
         "AND I TURNED MYSELF TO BEHOLD WISDOM, AND MADNESS, AND FOLLY:\n\
          FOR WHAT CAN THE MAN DO THAT COMES AFTER THE KING?\n\
          EVEN THAT WHICH HAS BEEN ALREADY DONE." )
      (c-loop
         (prin " ")
         (prinll (space-out EncMessage))
         (prin " ")
         (let (RenderedMessage (cryptogram-encrypt
                                  EncMessage
                                  (read-world-var
                                     "crypto-tablet-substitutions" ) ) )
            (prinll
               (space-out
                  (cryptogram-encrypt
                     EncMessage
                     (read-world-var "crypto-tablet-substitutions") ) ) )
            (when (= RenderedMessage DecMessage)
               (prinll "The puzzle is complete! Your new code is...")
               (prinll "BLUE-GREEN-BLUE")
               (break) ) )
         (prin "> ")
         (flush)
         (let (Cmd (mapcar 'text (str (line T))))
            (prinl)
            (when (= Cmd '("done"))
               (prinll "You set the tablet back on the table.")
               (break) )
            (when (and
                   (letter? (car Cmd))
                   (letter? (cadr Cmd)) )
               (let (L1 (uppc (car Cmd))
                     L2 (uppc (cadr Cmd)) )
                  (when (rassoc
                           L2
                           (aa-to-list
                              (read-world-var "crypto-tablet-substitutions") ) )
                     (set-world-var
                        "crypto-tablet-substitutions"
                        (aa-delete
                           (car @)
                           (read-world-var "crypto-tablet-substitutions") ) ) )
                  (set-world-var
                     "crypto-tablet-substitutions"
                     (aa-insert L1 L2
                        (read-world-var "crypto-tablet-substitutions") ) ) ) ) ) ) ) )

(de use-old-radio ()
   (prinll "You turn the tuning knob a little. You hear some static and \
            crackling as you settle on a station.")
   (case (rand 1 11)
      (1 (prinll "\"...Who knows what evil lurks in the hearts of men? The \
                    Shadow knows...\"") )
      (2 (prinll "\"...Ladies and gentlemen. The story you are about to \
                    hear is true. The names have been changed to \
                    protect the innocent...\"") )
      (3 (prinll "\"...Who's afraid of the big bad wolf? Tra la la la la...\""))
      (4 (prinll "\"...Hi-yo, Silver, away!...\""))
      (5 (prinll "\"...And the gold of her hair, crowns the blue of her eyes...\""))
      (6 (prinll "\"...We didn't exactly believe your story, Miss \
                       Wonderly. We believed your 200 dollars...\""))
      (7 (prinll "You hear the gentle notes of the Blue Danube."))
      (8 (prinll "You hear Sinatra's velvety voice singing \"Close To You\"."))
      (9 (prinll "You hear the fiery oration of a fundamentalist preacher."))
      (10 (prinll "\"...speak 'friend' and enter...\""))
      (11 (prinll "You hear a jazzy tune you don't recognize."))))

(de process-submarine-lock-mechanism (Action)
   (set-world-var "sub-unlock-sequence"
      (head 4
         (cons Action (read-world-var "sub-unlock-sequence")) ) )
   (when (= (read-world-var "sub-unlock-sequence")
            '("pull" "rotate" "push" "rotate") )
      (set-world-var "submarine-unlocked" T)
      (prinll "The hatch of the submarine suddenly becomes loose. You release that you \
               understand how the locking mechanism works and can enter and exit the \
               submarine at will.") ) )

(de process-stuck-sub-move (Action)
   (set-world-var "sub-unstuck-sequence"
      (head 6
         (cons Action (read-world-var "sub-unstuck-sequence")) ) )
   (when (let Sequence (read-world-var "sub-unstuck-sequence")
            (or (= Sequence '(up west east up west east))
               (= Sequence '(up east west up east west)) ) )
      (set-world-var "sub-unstuck" T)
      (prinll "With an effort, the submarine pulls itself free of the mud.") ) )

(de start-game ()
   (prinll "\n" "Dr. Theobold: A Text Adventure Game" "\n"
      "Copyright (C) 2017 Christopher Howard" "\n"
      "This program comes with ABSOLUTELY NO WARRANTY; for details type `warranty'." "\n"
      "This is free software, and you are welcome to redistribute it \
       under certain conditions; type `license' for details.")
   (print-help)
   (init-world)
   (enter-room "threshold")
   (read-loop) )

(de init-world ()
   (world
      (location "threshold")
      (room "threshold"
         (room-long-description "You are standing at the entrance to a \
                                 building, reputed to be the home of one \
                                 Dr. Theobold. The entrance is barred by \
                                 a steel door. There is a five digit \
                                 numeric keypad on the door. A rubber \
                                 mat lines the threshold.")
         (room-command '("search" "mat")
            '(() (prinll "You found a small note. It is a picture of a \
                          cherry pie." ) ) )
         (room-command '("use" "keypad") 'use-threshold-keypad)
         (room-exit "north" '(() (if (read-world-var "threshold-door-unlocked")
                                    (enter-room "atrium")
                                    (prinll "The door is locked") ) ) ) )
      (room "atrium"
         (room-long-description "You are in a large atrium. The walls are \
                                 covered in ornate carvings. The room is \
                                 mostly open and empty except a few chairs \
                                 and couches in the middle, centered \
                                 around a small table. A small computer \
                                 tablet is laying on the table. There is \
                                 a door heading back out to the front \
                                 entrance, and another door into a living room.")
         (room-exit "south" '(() (enter-room "threshold")))
         (room-exit "east" '(() (enter-room "living-room")))
         (room-command '("use" "tablet") '(() (use-crypto-tablet)))
         (room-command '("use" "computer" "tablet") '(() (use-crypto-tablet))) )
      (room "living-room"
         (room-long-description "You are in a cozy living room with a \
                                 fuzzy carpet and plush furniture. An \
                                 old-fashioned radio leans against the \
                                 wall. You also see an small elevator. \
                                 There are doors on the west, east, and \
                                 north walls.")
         (room-exit "west" '(() (enter-room "atrium")))
         (room-exit "north" '(() (prinll "The door is locked")))
         (room-exit "east" '(() (enter-room "kitchen")))
         (room-exit "down" '(() (if (read-world-var "elevator-unlocked")
                                   (enter-room "programming-room")
                                   (prinll "The elevator does not appear to be functional.") ) ) )
         (room-command '("use" "radio") '(() (use-old-radio)))
         (room-command '("use" "old" "radio") '(() (use-old-radio)))
         (let (elevator-release '(() (prog
                                        (prinll "You hear a buzzing noise \
                                                 coming from the elevator.")
                                        (set-world-var "elevator-unlocked" T) ) ) )
            (room-command '("speak" "friend") elevator-release)
            (room-command '("speak" "\"friend\"") elevator-release)
            (room-command '("say" "friend") elevator-release)
            (room-command '("say" "\"friend\"") elevator-release) )
         (room-command '("use" "old-fashioned" "radio") '(() (use-old-radio))) )
      (room "kitchen"
         (room-long-description
            "You find a kitchen that is sophisticated but slightly \
             messy. Remnants of frozen dinner packaging decorate the \
             counter tops. You see a refrigerator, and also a bulky \
             microwave with several tubes connected to it." )
         (room-command '("look" "at" "microwave")
            '(() (prog
                    (prinll "You see a label:")
                    (prinll "WARNING: POWERED BY FUSION. TEST \
                             CONTAINMENT COILS REGULARLY. COOKING \
                             TEMPERATURES MAY NOT MATCH CONVENTIONAL \
                             MICROWAVES." ) ) ) )
         (room-command '("search" "refrigerator")
            '(() (prog
                    (prinll "You found some eggs.")
                    (if (not (read-world-var "egg-counter"))
                       (set-world-var "egg-counter" 1)
                       (set-world-var "egg-counter" (inc (read-world-var "egg-counter"))) )
                    (unless (inventory-contains? "egg")
                       (add-to-inventory "egg"
                          (= (read-world-var "egg-counter") 4) )
                       (prinll "An egg has been added to your inventory.") ) ) ) )
         (room-command '("put" "egg" "in" "microwave")
            '(() (if (not (inventory-contains? "egg"))
                    (prinll "You do not have an egg.")
                    (if (read-world-var "microwave-contents")
                       (prinll "The microwave already has something in it.")
                       (prog
                          (if (not (get-inventory-data "egg"))
                             (set-world-var "microwave-contents" "egg")
                             (set-world-var "microwave-contents" "the egg") )
                          (remove-from-inventory "egg")
                          (prinll "You put an egg in the microwave.") ) ) ) ) )
         (room-command '("break" "egg")
            '(() (if (not (inventory-contains? "egg"))
                    (prinll "You do not have an egg.")
                    (if (get-inventory-data "egg")
                       (prinll "Surprisingly, the egg is solid and does not break.")
                       (prog
                          (remove-from-inventory "egg")
                          (prinll "The egg cracks and leaves a mess on the floor.") ) ) ) ) )
         (room-command '("use" "microwave")
            '(() (if (not (read-world-var "microwave-contents"))
                    (prinll "There is nothing in the microwave to cook.")
                    (if (= (read-world-var "microwave-contents") "egg")
                       (prog 
                          (set-world-var "microwave-contents" NIL)
                          (case (rand 1 4)
                             (1 (prinll "The egg explodes, covering the inside of the microwave with pieces of \
                                         shell and yolk."))
                             (2 (prinll "The egg bursts into a ball of plasma, then vaporizes into nothing."))
                             (3 (prinll "The egg implodes dramatically, bending space and time. For a brief \
                                         moment, you see a glimpse into another part of the universe, before the \
                                         tunnel collapses in on itself."))
                             (4 (prinll "The atomic structure of the egg breaks down and becomes a vortex of \
                                         spinning particles. For several seconds, the particles arrange \
                                         themselves into a beautiful crystalline structure, then dissipate, \
                                         settling and leaving a thin film on the microwave plate." ) ) ) )
                       # "the egg"
                       (prog
                          (prinll "The bulk of the egg-like object in the microwave melts away, leaving \
                                   behind a mysterious, glittering crystal.")
                          (add-to-inventory "crystal")
                          (set-world-var "microwave-contents" NIL)
                          (prinll "A crystal has been added to your inventory.") ) ) ) ) )
         (room-exit "west" '(() (enter-room "living-room"))) )
      (room "programming-room"
         (room-long-description "In the center of this room is a rotating chair, nested in an assortment \
                                 of keyboards and control panels, and surrounded above by a half dozen \
                                 huge flatscreen computer monitors.")
         (let force-field-block '(() (prinll "As you try to move closer, you hear a humming noise and feel yourself \
                                              pushed away by some kind of force field.") )
            (room-command '("use" "chair") force-field-block)
            (room-command '("sit" "in" "chair") force-field-block)
            (room-command '("use" "keyboard") force-field-block)
            (room-command '("use" "keyboards") force-field-block)
            (room-command '("use" "control" "panel") force-field-block)
            (room-command '("use" "control" "panels") force-field-block)
            (room-command '("use" "panel") force-field-block)
            (room-command '("use" "panels") force-field-block)
            (room-command '("use" "monitor") force-field-block)
            (room-command '("use" "monitors") force-field-block) )
         (let display-monitor '(() (prinll "The monitors are filled with mysterious computer codes embedded in \
                                            nested parentheses.") )
            (room-command '("look" "at" "monitor") display-monitor)
            (room-command '("look" "at" "monitors") display-monitor) )
         (room-exit "up" '(() (enter-room "living-room")))
         (room-exit "west" '(() (enter-room "water-entry"))) )
      (room "water-entry"
         (room-long-description "You are in a cavern with a tile floor and a small but deep pool of water \
                                 at one end. Metal pipes cover the walls. A small submarine, the right \
                                 size for one person, is docked near the edge of the water.")
         (room-command '("look" "at" "submarine")
            '(() (prinll "On the frame of the submarine, you see a lever, which can be either \
                          pushed or pulled, and a handle which rotates.") ))
         (room-command '("push" "lever")
            '(()
              (if (read-world-var "submarine-unlocked")
                 (prinll "You already understand how to use the locking mechanism.")
                 (prog
                    (prinll "You push the lever forward.")
                    (process-submarine-lock-mechanism "push") ) ) ) )
         (room-command '("pull" "lever")
            '(()
              (if (read-world-var "submarine-unlocked")
                 (prinll "You already understand how to use the locking mechanism.")
                 (prog
                    (prinll "You pull the lever back.")
                    (process-submarine-lock-mechanism "pull") ) ) ) )
         (let turn-cmd
            '(()
              (if (read-world-var "submarine-unlocked")
                 (prinll "You already understand how to use the locking mechanism.")
                 (prog
                    (prinll "You rotate the handle.")
                    (process-submarine-lock-mechanism "rotate") ) ) )
            (room-command '("rotate" "handle") turn-cmd)
            (room-command '("turn" "handle") turn-cmd) )
         (room-exit "east" '(() (enter-room "programming-room")))
         (room-exit "down"
            '(() (if (not (read-world-var "submarine-unlocked"))
                    (prinll "You try to enter the submarine but cannot find an opening.")
                    (prog
                       (prinll "You enter the submarine. After figuring out the engine and directional \
                                controls, you dive the vessel down into the pool.")
                       (enter-room "water-passage-1") ) ) ) ) )
      (let prefix-sub-description
         '((Str)
           (pack ""
              (list "You are inside a single person submarine. You are able to steer the \
                     craft in any available direction. An advanced set of mechanical \
                     appendages allows you to manipulate objects outside the boat, or even \
                     suck small objects into the cabin. Lights on the vessel brighten the \
                     surrounding water." "\n\n" Str ) ) )
         (room "water-passage-1"
            (room-long-description
               (prefix-sub-description
                  "Outside the viewports you see you are in a water filled cavern that continues \
                   upward and downward." ) )
            (room-exit "up" '(() (enter-room "water-entry")))
            (room-exit "down" '(() (enter-room "water-passage-2"))) )
         (room "water-passage-2"
            (room-long-description
               (prefix-sub-description
                  "Outside the viewports you see you are in a water filled cavern that continues \
                   upwards and downwards." ) )
            (room-exit "up" '(() (enter-room "water-passage-1")))
            (room-exit "down"
               '(() (unless (read-world-var "sub-unstuck")
                       (prinll "You feel a jarring thud as the submarine collides with the bottom of the \
                                tunnel and embeddes itself deeply into some gooey mud."))
                 (enter-room "mud-trap") ) ) )
         (room "mud-trap"
            (room-long-description
               (prefix-sub-description
                  "The cavern bottoms out here into a pit of thick mud. Through the \
                   viewports, you can see an opening above, as well off toward the west \
                   and toward the east." ) )
            (room-exit "up"
               '(() (if (read-world-var "sub-unstuck")
                       (enter-room "water-passage-2")
                       (prog
                          (prinll "You attempt to raise the vessel, pulling it against the mud.")
                          (process-stuck-sub-move 'up) ) ) ) )
            (room-exit "west"
               '(() (if (read-world-var "sub-unstuck")
                       (enter-room "water-passage-3")
                       (prog
                          (prinll "You throttle forwards, nudging the submarine a little through the mud. \
                                   Fortunately, the propellers are above the top of the mud.")
                          (process-stuck-sub-move 'west) ) ) ) )
            (room-exit "east"
               '(() (if (read-world-var "sub-unstuck")
                       (enter-room "water-passage-4")
                       (prog
                          (prinll "You throttle backwards, nudging the submarine a little through the mud. \
                                   Fortunately, the propellers are above the top of the mud.")
                          (process-stuck-sub-move 'east) ) ) ) ) )
         (room "water-passage-3"
            (room-long-description
               (prefix-sub-description
                  "Outside the viewports you see you are in a water filled cavern that continues \
                   to the west and to the east." ))
            (room-exit "west" '(() (enter-room "water-passage-5")))
            (room-exit "east" '(() (enter-room "mud-trap"))) )
         (room "water-passage-4"
            (room-long-description
               (prefix-sub-description
                  "You are in an area that has not yet been coded. Digital oblivion!" ) )
            (room-exit "west" '(() (enter-room "mud-trap"))) )
         (room "water-passage-5"
            (room-long-description
               (prefix-sub-description
                  "Outside the viewports you see you are in a water filled cavern that continues \
                   to the north and to the east." ))
            (room-exit "north" '(() (enter-room "ladder-cavern")))
            (room-exit "east" '(() (enter-room "water-passage-4"))) )
         (room "water-passage-5"
            (room-long-description
               (prefix-sub-description
                  "Outside the viewports you see you are in a water filled cavern that continues \
                   to the north and to the east. The tunnel to the north looks narrow and low but \
                   should be large enough for the submarine." ))
            (room-exit "north" '(() (enter-room "ladder-cavern")))
            (room-exit "east" '(() (enter-room "water-passage-4"))) )
         (room "ladder-cavern"
            (room-long-description
               (prefix-sub-description
                  "Your submarine is in a bottle shaped cave mostly filled with water. The top \
                   narrows some more and you see a bubble of air, large enough that you can open \
                   the hatch into it. A sturdy ladder hangs down out of a hole in the ceiling." ))
            (room-exit "south" '(() (enter-room "water-passage-5")))
            (room-exit "up" '(() (prinll "You wish to climb the ladder, but sense that the room \
                                          above has not yet been coded." )))))
 ) )
