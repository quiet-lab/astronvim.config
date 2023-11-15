#                              KMonad: Guided tour

  Welcome to the KMonad configuration tutorial. This document aims to explain:
  1. The configuration syntax
  2. The required information
  3. All possible configuration options

  This document should be a runnable configuration, so with some tweaks to the
  `defcfg` block (see below) you should be able to try out all the examples
  interactively.

##                     Basic syntax: comments and parentheses

  KMonad's configuration language is styled on various lisps, like scheme or
  Common Lisp. In a lisp, every statement is entered between `(` and `)`s. If
  you are more used to Fortran style languages (python, ruby, C, Java, etc.), the
  change is quite straightforward: the function name moves into the parentheses,
  and you don't use commas to separate arguments. I.e.

  - This:     `my_function(a, 3, "Alakazam")`
  - Becomes:  `(my_function a 3 "Alakazam")`

  The reason for this is because Lisp-style languages are very easy to parse and
  write syntax-highlighters for.

  We also provide standard Lisp syntax for comments:
  - block comments between: `#|` and its reverse
  - line comments following: `;;`

  Unlike standard lisp, a single `;` does not denote a comment, but instead the
  keycode for semicolon.

  Also, as you might have noticed, whitespace is possible anywhere.

  To check for syntax errors while editing, invoke KMonad with the -d option.

##                        Necessary: the `defcfg` block

  There are a few bits of information that are required to be present in a
  KMonad configuration file. One of these is the existence of exactly 1 `defcfg`
  statement. This statement is used to customize various configuration settings.
  Many of these settings have default values, but a minimal definition must
  include at least an 'input' field and an 'output' field. These describe how
  KMonad captures its inputs and how it emits its outputs.

  First, let's go over the optional, non-OS specific settings. Currently there
  are only 2:

  - fallthrough: `true` or `false`, defaults to `false`

    KMonad catches input events and tries to match them to various handlers. If
    it cannot match an event to any handler (for example, if it isn't included
    in the `defsrc` block, or if it is, but the current keymap does not map any
    buttons to it), then the event gets quietly ignored. If `fallthrough` is set
    to `true`, any unhandled events simply get reemitted.

  - allow-cmd: `true` or `false`, defaults to `false`

    If this is set to `false`, any action that runs a shell-command will simply
    log to `stdout` without ever running (log-level info). Don't ever enable
    this on a configuration that you do not trust, because:

    ~~~lisp
      (cmd-button "rm -rf ~/*")
    ~~~


    is a thing. For more information on the `cmd-button' function, see the
    section on Command buttons below.

  There are also some optional OS specific settings that we support:

  - `cmp-seq`: `KEY`, defaults to `RightAlt` (Linux X11 specific)

    This sets your compose key for Unicode input. For more information, as well
    as a workaround to also make this work on windows, see the section on
    Compose-key sequences below.

  - `cmp-seq-delay`: `NUMBER` (in milliseconds)

    This sets a delay between each pressed key in a compose-key sequence.  Some
    environments may have troubles recognizing the key sequence if it's pressed
    too rapidly; if you experience any problems in this direction, you can try
    setting this value to `5` or `10` and see if that helps.

  Secondly, let's go over how to specify the `input` and `output` fields of a
  `defcfg` block. This differs between OS'es, and so do the capabilities of
  these interfaces.


  ## Linux

  In Linux we deal with input by performing an ioctl-grab on a specific
  device-file. This allows us to hook KMonad on the input of exactly 1 keyboard,
  and allows you to run multiple instances of KMonad for different keyboards. We
  make an input using:
  ~~~lisp
    (device-file "/dev/input/by-id/my-keyboard-kbd")
  ~~~

  > NOTE: Any valid path to a device-file will work, but it is recommended to use
  the `by-id` directory, since these names will not change if you replug the
  device.

  We deal with output by creating a `uinput` device. This requires that the
  `uinput` kernel module is loaded. The easiest way to ensure this is by calling
  `sudo modprobe uinput`. We create a uinput device using:
  ~~~lisp
    (uinput-sink "name" "optional post-init command")
  ~~~


 ##  Windows

  In Windows we do not get such fine-grained control. We use a low-level
  keyboard hook to intercept all non-injected keyboard events. There is
  currently an open issue to improve the C-bindings used to capture windows
  keyevents, and if you have a better way to approach this issue, help is deeply
  appreciated. You specify a windows input using:
~~~lisp
    (low-level-hook)
~~~
  Similarly, the output in Windows lacks the fine-grained control. We use the
  SendEvent API to emit key events directly to Windows. Since these are
  'artificial' events we won't end up catching them again by the
  `low-level-hook`. It is very likely that KMonad does not play well with other
  programs that capture keyboard input like AHK. You specify windows output using:
~~~lisp
    (send-event-sink)
~~~

  Specific to Windows, KMonad also handles key auto-repeat.  Therefore your
  Windows system settings for key repeat delay and key repeat rate will have no
  effect when KMonad is running.  To set the repeat delay and rate from KMonad,
  pass the optional arguments pair to `send-event-sink`:
  ~~~lisp
    (send-event-sink [ <delay> <rate> ])
  ~~~
  where:
   `<delay>`: how many ms before a key starts repeating
   `<rate>`: how many ms between each repeat event
  A value of 500 ms delay and 30 ms rate should mimic the default Windows
  settings pretty well:
  ~~~lisp
    (send-event-sink 500 30)
  ~~~


  ## Mac OS

  For Mac questions I suggest filing an issue and tagging @thoelze1, he wrote
  the MacOS API. However, input using:
  ~~~lisp
    (iokit-name "optional product string")
  ~~~

  By default this should grab all keyboards, however if a product string is
  provided, KMonad will only capture those devices that match the provided
  product string. If you would like to provide a product string, you can run
  `make; ./list-keyboards` in c_src/mac to list the product strings of all
  connected keyboards.

  You initialize output on MacOS using:
  ~~~lisp
    (kext)
  ~~~
-----
~~~lisp
(defcfg
  ;; For Linux
  input  (device-file "/dev/input/by-id/usb-04d9_daskeyboard-event-kbd")
  output (uinput-sink "My KMonad output"
    ;; To understand the importance of the following line, see the section on
    ;; Compose-key sequences at the near-bottom of this file.
    "/run/current-system/sw/bin/sleep 1 && /run/current-system/sw/bin/setxkbmap -option compose:ralt")
  cmp-seq ralt    ;; Set the compose key to `RightAlt'
  cmp-seq-delay 5 ;; 5ms delay between each compose-key sequence press

  ;; For Windows
  ;; input  (low-level-hook)
  ;; output (send-event-sink)

  ;; For MacOS
  ;; input  (iokit-name "my-keyboard-product-string")
  ;; output (kext)

  ;; Comment this if you want unhandled events not to be emitted
  fallthrough true

  ;; Set this to false to disable any command-execution in KMonad
  allow-cmd true
)
~~~


##                    Necessary: the `defsrc` block

  It is difficult to explain the `defsrc` block without immediately going into
  `deflayer` blocks as well. Essentially, KMonad maps input-events to various
  internal actions, many of which generate output events. The `defsrc` block
  explains the layout on which we specify our `deflayer`s down the line.

  It is important to realize that the `defsrc` block doesn't *necessarily* have
  to coincide with your actual input keyboard. You can specify a full 100%
  `defsrc` block, but only use a 40% keyboard. This will mean that every
  `deflayer` you specify will also have to match your 100% `defsrc`, and that
  your actual keyboard would be physically unable to trigger about 60% of your
  keymap, but it would be perfectly valid syntax.

  The dual of this (and more useful) is that it is also perfectly valid to only
  specify that part of your keyboard in `defsrc` that you want to remap. If you
  use a 100% keyboard, but don't want to remap the numpad at all you can simply
  leave the numpad out of your `defsrc`, and it should work just fine. In that
  particular case you probably want to set `fallthrough` to `true` in your
  `defcfg` block though.

  In the future we would like to provide support for multiple, named `defsrc`
  blocks, so that it becomes easier to specify various layers for just the
  numpad, for example, but at the moment any more or less than 1 `defsrc` block
  will result in an error.

  The layouting in the `defsrc` block is completely free, whitespace simply gets
  ignored. We strive to provide a name for every keycode that is no longer than
  4 characters, so we find that laying out your keymap in columns of 5 works out
  quite nicely (although wider columns will allow for more informative aliases,
  see below).

  Most keycodes should be obvious. If you are unsure, check
  `./src/KMonad/Keyboard/Keycode.hs`. Every Keycode has a name corresponding to
  its Keycode name, but all lower-case and with the 'Key' prefix removed. There
  are also various aliases for Keycodes starting around line 350. If you are
  trying to bind a key and there is not a 4-letter alias, please file an issue,
  or better yet, a pull-request, and it will be added promptly.

  Also, you can consult `./keymap/template/` for various input templates to use
  directly or to look up keycodes by position. Here we use the input-template
  for 'us_ansi_60.kbd'
~~~lisp
(defsrc
  grv  1    2    3    4    5    6    7    8    9    0    -    =    bspc
  tab  q    w    e    r    t    y    u    i    o    p    [    ]    \
  caps a    s    d    f    g    h    j    k    l    ;    '    ret
  lsft z    x    c    v    b    n    m    ,    .    /    rsft
  lctl lmet lalt           spc            ralt rmet cmp  rctl
)
~~~
##                        Optional : `defalias` statements

  KMonad will let you specify some very specific, crazy buttons. These
  definitions can get pretty long, though, and would make `deflayer` blocks
  nearly impossible to read. Therefore we provide the ability to alias names to
  these buttons, to keep the actual `deflayer` statements orderly.

  A `defalias` can contain any number of aliases, and it can refer backwards or
  forwards to layers without issue. The only sequencing that needs to be kept in
  mind is that a `defalias` cannot refer forward to another `defalias` that is
  not yet defined.

  Here we define a few aliases, but we will define more later. Notice that we
  try to only use 3 letter names for aliases. If that is not enough to be clear,
  consider widening all columns to 6 or 7 characters (or be content with a messy
  config).
~~~lisp
(defalias
  num  (layer-toggle numbers) ;; Bind num to a button that switches to a layer
  kil  C-A-del                ;; Bind kil to a button that Ctrl-Alt-deletes
)
~~~
> NOTE: The above code could just as easily have been written as:
~~~lisp
(defalias num (layer-toggle numbers))
(defalias kil C-A-del)
~~~
##                     Necessary: at least 1 `deflayer` block

  As explained in the `defsrc` section, a `deflayer` will define a button for
  each corresponding entry in the `defsrc` definition. A `deflayer` statement
  consists of the `deflayer` keyword, followed by the name used to identify this
  layer, followed by N 'statements-that-evaluate-to-a-button', where N is
  exactly how many entries are defined in the `defsrc` statement.

  It is also important to mention that the `keymap` in KMonad is modelled as a
  stack of layers (just like in QMK). When an event is registered we look in the
  top-most layer for a handler. If we don't find one we try the next layer, and
  then the next.

  Exactly what `evaluates-to-a-button` will be expanded on in more detail below.
  There are very many different specialist buttons in KMonad that we will touch
  upon. However, for now, these 4 are a good place to begin:

  1. Any keycode evaluates to a button that, on press, emits the press of that
     keycode, and on release, emits the release of that keycode. Just a 'normal'
     button. The exception is `\`, which gets used as an escape character. Use
     `\\` instead. Other characters that need to be escaped to match the literal
     character are `(`, `)`, and `_`.

  2. An @-prefixed name evaluates to an alias lookup. We named two buttons in
     the `defalias` block above, we could now refer to these buttons using
     `@num` and `@kil`. This is also why we only use alias-names no longer than
     3 characters in this tutorial. Also, note that we are already referencing
     some aliases that have not yet been defined, this is not an issue.

  3. The `_` character evaluates to transparent. I.e. no handler for that
     key-event in this layer, causing this event to be handed down the layer
     stack to perhaps be handled by the next layer.

  4. The `XX` character evaluates to blocked. I.e. no action bound to that
     key-event in this layer, but do actually catch event, preventing any
     underlying layer from handling it.

  Finally, it is important to note that the *first* `deflayer` statement in a
  KMonad config will be the layer that is active when KMonad starts up.
  ~~~lisp
  (deflayer qwerty
    grv  1    2    3    4    5    6    7    8    9    0    -    =    bspc
    tab  q    w    e    r    t    y    u    i    o    p    [    ]    \
    caps a    s    d    f    g    h    j    k    l    ;    '    ret
    lsft z    x    c    v    b    n    m    ,    .    /    rsft
    lctl @num lalt           spc            ralt rmet @sym @tst
  )
  ~~~
##                   Optional: as many layers as you please

  We had already defined `num` as referring to a `(layer-toggle numbers)`. We
  will get into layer-manipulation soon, but first, let's just create a second
  layer that overlays a numpad under our right-hand.

  To easily specify layers it is highly recommended to create an empty
  `deflayer` statement as a comment at the top of your config, so you can simply
  copy-paste this template. There are also various empty layer templates
  available in the `./keymap/template` directory.
  ~~~lisp
  (deflayer numbers
    _    _    _    _    _    _    _    _    _    _    _    _    _    _
    _    _    _    _    _    XX   /    7    8    9    -    _    _    _
    _    _    _    _    _    XX   *    4    5    6    +    _    _
    _    _    \(   \)   .    XX   0    1    2    3    _    _
    _    _    _              _              _    _    _    _
  )
  ~~~
##                        Optional: modded buttons

  Let's start by exploring the various special buttons that are supported by
  KMonad by looking at 'modded' buttons, that is to say, buttons that activate
  some kind of 'mod', then perform some button, and finally release that 'mod'
  again.

  We have already seen an example of this style of button, our `kil` button is
  one such button. Let's look at it in more detail:
    `C-A-del`

  This looks like a simple declarative statement, but it's helpful to realize
  that is simply syntactic sugar around 2 function calls. This statement is
  equivalent to:
  ~~~lisp
    (around ctl (around alt del))
  ~~~
  This highlights a core design principle in KMonad: we try to provide very
  simple buttons, and then we provide rules and functions for combining them
  into new buttons. Although note: still very much a work in progress.

  So, looking at this statement:
  ~~~lisp
    (around foo bar)
  ~~~

  Here, `around` is a function that takes two buttons and creates a new button.
  This new button will, on a press, first press foo, then press bar, and on a
  release first release bar, and then foo. Once created, this new button can be
  passed to anything in KMonad that expects a button.

  We have already seen other examples of modded buttons, `\(`, `\)`, `*`, and `+`. There
  are no Keycodes for these buttons in KMonad, but they are buttons. They simply
  evaluate to `(around lsft x)`. All shifted numbers have their corresponding
  characters, the same is true for all capitals, and `< > : ~ " | { } \_ +` and `?`.

  To wrap up `modded-buttons`, let's look back at `C-A-del`. We have 8 variants:
  - `C- : (around lctl X)`
  - `A- : (around lalt X)`
  - `M- : (around lmet X)`
  - `S- : (around lsft X)`

  Then `RC-`, `RA-`, `RM-`, and `RS-` behave exactly the same, except using the
  right-modifier.

  These can be combined however you please:
  ~~~lisp
    C-A-M-S-x          ;; Perfectly valid
    C-%                ;; Perfectly valid: same as C-S-5
    C-RC-RA-A-M-S-RS-m ;; Sure, but why would you?
  ~~~

  Also, note that although we provide special syntax for certain modifiers,
  these buttons are in no way 'special' in KMonad. There is no concept of
  `modifier`:
  ~~~lisp
    (around a (around b c)) ;; Perfectly valid
  ~~~

  ~~~lisp
  (defalias

    ;; Something useful
    cpy C-c
    pst C-v
    cut C-x

    ;; Something silly
    md1 (around a (around b c))    ;; abc
    md2 (around a (around lsft b)) ;; aB
    md3 C-A-M-S-l
    md4 (around % b)               ;; BEWARE: %B, not %b, do you see why?
  )
  ~~~

##                        Optional: sticky keys

  KMonad also supports so called `sticky keys`.  These are keys that will
  behave as if they were pressed after just tapping them.  This behaviour
  wears off after the next button is pressed, which makes them ideal for
  things like a quick control or shift. For example, tapping a sticky and
  then pressing `abc` will result in `Abc`.

  You can create these keys with the `sticky-key` keyword:
  ~~~lisp
    (defalias
      slc (sticky-key 500 lctl))
  ~~~
  The number after `sticky-key` is the timeout you want, in milliseconds.  If
  a key is tapped and that time has passed, it won't act like it's pressed
  down when we receive the next keypress.

  It is also possible to combine sticky keys.  For example, to
  get a sticky shift+control you can do
  ~~~lisp
    (defalias
      ssc (around
           (sticky-key 500 lsft)
           (sticky-key 500 lctl)))
  ~~~

  Let's make both shift keys sticky
  ~~~lisp
  (defalias
    sl (sticky-key 300 lsft)
    sr (sticky-key 300 rsft))
  ~~~
  Now we define the 'tst' button as opening and closing a bunch of layers at
  the same time. If you understand why this works, you're starting to grok
  KMonad.

  Explanation: we define a bunch of testing-layers with buttons to illustrate
  the various options in KMonad. Each of these layers makes sure to have its
  buttons not overlap with the buttons from the other layers, and specifies all
  its other buttons as transparent. When we use the nested `around` statement,
  whenever we push the button linked to '@tst' (check `qwerty` layer, we bind
  it to `rctl`), any button we press when holding `rctl` will be pressed in the
  context of those 4 layers overlayed on the stack. When we release `rctl`, all
  these layers will be popped again.
  ~~~lisp
  (defalias tst (around (layer-toggle macro-test)
                  (around (layer-toggle layer-test)
                    (around (layer-toggle around-next-test)
                      (around (layer-toggle command-test)
                              (layer-toggle modded-test))))))

  (deflayer modded-test
    _    _    _    _    _    _    _    _    _    _    _    _    _    _
    _    _    @md4 _    _    _    _    _    _    _    _    _    _    _
    _    _    @md1 @md2 @md3 _    _    _    _    _    _    _    _
    _    _    @cut @cpy @pst _    _    _    _    _    _    _
    _    _    _              _              _    _    _    _
  )
  ~~~
##                            Optional: tap-macros
  Let's look at a button we haven't seen yet, tap-macros.

  `tap-macro` is a function that takes an arbitrary number of buttons and
  returns a new button. When this new button is pressed it rapidly taps all its
  stored buttons in quick succesion except for its last button, which it only
  presses. This last button gets released when the `tap-macro` gets released.

  There are two ways to define a `tap-macro`, using the `tap-macro` function
  directly, or through the #() syntactic sugar. Both evaluate to exactly the
  same button.
  ~~~lisp
    (tap-macro K M o n a d)
    #(K M o n a d)
  ~~~

  If you are going to use a `tap-macro` to perform a sequence of actions inside
  some program you probably want to include short pauses between inputs to give
  the program time to register all the key-presses. Therefore we also provide
  the 'pause' function, which simply pauses processing for a certain amount of
  milliseconds. Pauses can be created like this:
  ~~~lisp
    (pause 20)
    P20
  ~~~

  You can also pause between each key stroke by specifying the `:delay' keyword,
  as well as a time in ms, at the end of a `tap-macro':
  ~~~lisp
    (tap-macro K M o n a d :delay 5)
    #(K M o n a d :delay 5)
  ~~~
  The above would be equivalent to
  ~~~lisp
    (tap-macro K P5 M P5 o P5 n P5 a P5 d)
  ~~~
  The `tap-macro-release` is like `tap-macro`, except that it
  waits to press the last button when the `tap-macro-release`
  gets released.  It might be useful when combined with a
  footswitch that sends keyboard scan codes.
  ~~~lisp
    (tap-macro-release i K M o n a d esc)
  ~~~

  > WARNING: DO NOT STORE YOUR PASSWORDS IN PLAIN TEXT OR IN YOUR KEYBOARD

  I know it might be tempting to store your password as a macro, but there are 2
  huge risks:
  1. You accidentally leak your config and expose your password
  2. Anyone who knows about the button can get clear-text representation of your
     password with any text editor, shell, or text-input field.

  Support for triggering shell commands directly from KMonad is described in the
  command buttons section below.

  This concludes this public service announcement.
  ~~~lisp
  (defalias
    mc1 #(K M o n a d)
    mc2 #(C-c P50 A-tab P50 C-v) ;; Careful, this might do something
    mc3 #(P200 h P150 4 P100 > < P50 > < P20 0 r z 1 ! 1 ! !)
    mc4 (tap-macro a (pause 50) @md2 (pause 50) c)
    mc5 (tap-macro-release esc esc esc)
    mc6 #(@mc3 spc @mc3 spc @mc3)
  )

  (deflayer macro-test
    _    @mc1 @mc2 @mc3 @mc4 @mc5 @mc6 _    _    _    _    _    _    _
    _    _    _    _    _    _    _    _    _    _    _    _    _    _
    _    _    _    _    _    _    _    _    _    _    _    _    _
    _    _    _    _    _    _    _    _    _    _    _    _
    _    _    _              _              _    _    _    _
  )
  ~~~


##                      Optional: layer manipulation

  You have already seen the basics of layer-manipulation. The `layer-toggle`
  button. This button adds a layer to the top of KMonad's layer stack when
  pressed, and removes it again when released. There are a number of other ways
  to manipulate the layer stack, some safer than others. Let's go through all of
  them from safest to least safe:

  `layer-toggle` works as described before, 2 things to note:
  1. If you are confused or worried about pressing a key, changing layers, and
     then releasing a key and this causing issues: don't be. KMonad handles
     presses and releases in very different ways. Presses get passed directly to
     the stacked keymap as previously described. When a KMonad button has its
     press-action triggered, it then registers a callback that will catch its
     own release before we ever touch the keymap. This guarantees that the
     button triggered by the press of X *will be* the button whose release is
     triggered by the release of X (the release of X might trigger other things
     as well, but that is besides the point.)
  2. If `layer-toggle` can only ever add and then necessarily remove 1 layer
     from the stack, then it will never cause a permanent change, and is
     perfectly safe.

  `layer-delay`, once pressed, temporarily switches to some layer for some
  milliseconds. Just like `layer-toggle` this will never permanently mess-up the
  layer stack. This button was initially implemented to provide some
  'leader-key' style behavior. Although I think in the future better solutions
  will be available. For now this will temporarily add a layer to the top of the
  stack:
  ~~~lisp
    (layer-delay 500 my-layer)
  ~~~
  `layer-next`, once pressed, primes KMonad to handle the next press from some
  arbitrary layer. This aims to fill the same usecase as `layer-delay`: the
  beginnings of 'leader-key' style behavior. I think this whole button will get
  deleted soon, because the more general `around-next` now exists (see below)
  and this is nothing more than:
  ~~~lisp
    (around-next (layer-toggle layer-name))
  ~~~
  Until then though, use `layer-next` like this:
  ~~~lisp
    (layer-next layer-name)
  ~~~
  `layer-switch`: change the base-layer of KMonad. As described at the top of
  this document, the first `deflayer` statement is the layer that is active when
  KMonad starts. Since `layer-toggle` can only ever add on and remove from the
  top of that, it can never change the base-layer. The following button will
  unregister the bottom-most layer of the keymap, and replace it with another
  layer:
  ~~~lisp
    (layer-switch my-layer)
  ~~~
  This is where things start getting potentially dangerous (i.e. get KMonad into
  an unusuable state until a restart has occured). It is perfectly possible to
  switch into a layer that you can never get out of. Or worse, you could
  theoretically have a layer full of only `XX`s and switch into that, rendering
  your keyboard unuseable until you somehow manage to kill KMonad (without using
  your keyboard).

  However, when handled well, `layer-switch` is very useful, letting you switch
  between 'modes' for your keyboard. I have a tiny keyboard with a weird keymap,
  but I switch into a simple 'qwerty' keymap shifted 1 button to the right for
  gaming. Just make sure that any 'mode' you switch into has a button that
  allows you to switch back out of the 'mode' (or content yourself restarting
  KMonad somehow).

  `layer-add` and `layer-rem`. This is where you can very quickly cause yourself
  a big headache. Originally I didn't expose these operations, but someone
  wanted to use them, and I am not one to deny someone else a chainsaw. As the
  names might give away:
    (layer-add name) ;; Add a layer to the top of the stack
    (layer-rem name) ;; Remove a layer by name (noop if no such layer)

  To use `layer-add` and `layer-rem` well, you should take a moment to think
  about how to create a layout that will prevent you from getting into
  situations where you enter a key-configuration you cannot get out of again.
  These two operations together, however, are very useful for activating a
  permanent overlay for a while. This technique is illustrated in the tap-hold
  overlay a bit further down.
  ~~~lisp
  (defalias

    yah (layer-toggle asking-for-trouble) ;; Completely safe
    nah (layer-add asking-for-trouble)    ;; Completely unsafe

    ld1 (layer-delay 500 numbers) ;; One way to get a leader-key
    ld2 (layer-next numbers)      ;; Another way to get a leader key

    ;; NOTE, this is safe because both `qwerty` and `colemak` contain the `@tst`
    ;; button which will get us to the `layer-test` layer, which itself contains
    ;; both `@qwe` and `@col`.
    qwe (layer-switch qwerty) ;; Set qwerty as the base layer
    col (layer-switch colemak) ;; Set colemak as the base layer
  )
  (deflayer layer-test
    @qwe _    _    _    _    _    _    _    _    _    _    @add _    @nah
    @col _    _    _    _    _    _    _    _    _    _    _    _    @yah
    _    _    _    _    _    _    _    _    _    _    _    _    _
    _    _    _    _    _    _    _    _    _    @ld1 @ld2 _
    _    _    _              _              _    _    _    _
  )

  ;; Exactly like qwerty, but with the letters switched around
  (deflayer colemak
    grv  1    2    3    4    5    6    7    8    9    0    -    =    bspc
    tab  q    w    f    p    g    j    l    u    y    ;    [    ]    \
    @xcp a    r    s    t    d    h    n    e    i    o    '    ret
    @sl  z    x    c    v    b    k    m    ,    .    /    @sr
    lctl @num lalt           spc            ralt rmet @sym @tst
  )

  (defalias lol #(: - D))

  ;; Contrived example
  (deflayer asking-for-trouble
    @lol @lol @lol @lol @lol @lol @lol @lol @lol @lol @lol @lol @lol @lol
    @lol @lol @lol @lol @lol @lol @lol @lol @lol @lol @lol @lol @lol @lol
    @lol @lol @lol @lol @lol @lol @lol @lol @lol @lol @lol @lol @lol
    @lol @lol @lol @lol @lol @lol @lol @lol @lol @lol @lol @lol
    @lol @lol @lol           @lol           @lol @lol @lol @lol
  )

  ;; One way to safely use layer-add and layer-rem: the button bound to layer-add
  ;; is the same button bound to layer-rem in the layer that `add` adds to the
  ;; stack. I.e., it becomes impossible to add or remove multiple copies of a
  ;; layer.
  (defalias
    add (layer-add multi-overlay) ;; multi-overlay is defined in the next
    rem (layer-rem multi-overlay) ;; section below this
  )
  ~~~
##                        Optional: Multi-use buttons

  Perhaps one of the most useful features of KMonad, where a lot of work has
  gone into, but also an area with many buttons that are ever so slightly
  different. The naming and structuring of these buttons might change sometime
  soon, but for now, this is what there is.

  For the next section being able to talk about examples is going to be handy,
  so consider the following scenario and mini-language that will be the same
  between scenarios:

  - We have some button `foo` that will be different between scenarios
  - `foo` is bound to `Esc` on the input keyboard
  - the letters a s d f are bound to themselves
  - Px signifies the press of button x on the keyboard
  - Rx signifies the release of said button
  - Tx signifies the sequential and near instantaneous press and release of x
  - 100 signifies 100ms pass

  So for example:
  > Tesc Ta:
      tap of 'Esc' (triggering `foo`), tap of 'a' triggering `a`
    Pesc 100 Ta Tb Resc:
      press of 'Esc', 100ms pause, tap of 'a', tap of 'b', release of 'Esc'

  The `tap-next` button takes 2 buttons, one for tapping, one for holding, and
  combines them into a single button. When pressed, if the next event is its own
  release, we tap the 'tapping' button. In all other cases we first press the
  'holding' button then we handle the event. Then when the `tap-next` gets
  released, we release the 'holding' button.

  So, using our mini-language, we set foo to:
    (tap-next x lsft)
  Then:
    Tesc            -> x
    Tesc Ta         -> xa
    Pesc Ta Resc    -> A
    Pesc Ta Tr Resc -> AR

  The `tap-hold` button is very similar to `tap-next` (a theme, trust me). The
  difference lies in how the decision is made whether to tap or hold. A
  `tap-hold` waits for a particular timeout, if the `tap-hold` is released
  anywhere before that moment we execute a tap immediately. If the timeout
  occurs and the `tap-hold` is still held, we switch to holding mode.

  The additional feature of a `tap-hold` is that it pauses event-processing
  until it makes its decision and then rolls back processing when the decision
  has been made.

  So, again with the mini-language, we set foo to:
    (tap-hold 200 x lsft) ;; Like tap-next, but with a 200ms timeout
  Then:
    Tesc            -> x
    Tesc Ta         -> xa
    Pesc 300 a      -> A (the moment you press a)
    Pesc a 300      -> A (after 200 ms)
    Pesc a 100 Resc -> xa (both happening immediately on Resc)

  The `tap-hold-next` button is a combination of the previous 2. Essentially,
  think of it as a `tap-next` button, but it also switches to held after a
  period of time. This is useful, because if you have a (tap-next ret ctl) for
  example, and you press it thinking you want to press C-v, but then you change
  your mind, you now cannot release the button without triggering a 'ret', that
  you then have to backspace. With the `tap-hold-next` button, you simply
  outwait the delay, and you're good. I see no benefit of `tap-next` over
  `tap-hold-next` with a decent timeout value.

  You can use the `:timeout-button` keyword to specify a button other than the
  hold button which should be held when the timeout expires. For example, we
  can construct a button which types one x when tapped, multiple x's when held,
  and yet still acts as shift when another button is pressed before the timeout
  expires. So, using the minilanguage and foo as:
    (tap-hold-next 200 x lsft :timeout-button x)
  Then:
    Tesc           -> Tx
    Pesc 100 a     -> A (the moment you press a)
    Pesc 5000 Resc -> xxxxxxx (some number of auto-repeated x's)

  Note that KMonad does not itself auto-repeat the key. In this last example,
  KMonad emits 200 Px 4800 Rx, and the operating system's auto-repeat feature,
  if any, emits multiple x's because it sees that the x key is held for 4800 ms.

  A note about tap action duration:
  For simplicity we reuse the `tap-next` example above, set foo to:
    (tap-next x lsft)
  Now, any keystroke performed by baseline human will have some duration, a
  'Tesc' is actually 'Pesc <some time passed> Resc'.  A true tap 'Tesc' with no
  delay between the press and release will sometime experience registration
  problems in programs.  However the tap action performed by KMonad IS this kind
  of 'true tap', that is:
    Tesc (Pesc 100 Resc) -> Px Rx
  For various reasons we do not want KMonad to have some default duration in the
  tap action it performs.  If you are having issues in programs, you can instead
  use the aforementioned `around` and `pause` function to give the tap action
  some duration.  Set foo to:
    (tap-next (around x (pause 2000)) lsft)
  or equivalently:
    (tap-next (around x P2000) lsft)
  then we have:
    Tesc (Pesc 100 Resc) -> Px 2000 Rx
  2000 ms is just for you to distinctively see the effect, in practice 35 ms
  should be enough for most scenarios (slightly longer than 2 frames in 60 fps).

  The `tap-next-release` is like `tap-next`, except it decides whether to tap or
  hold based on the next release of a key that was *not* pressed before us. This
  also performs rollback like `tap-hold`. So, using the minilanguage and foo as:
    (tap-next-release x lsft)
  Then:
    Tesc Ta         -> xa
    Pa Pesc Ra Resc -> ax (because 'a' was already pressed when we started, so
                           foo decides it is tapping)
    Pesc Pa Resc Ra -> xa (because the first release we encounter is of esc)
    Pesc Ta Resc    -> A (because a was pressed *and* released after we started,
                          so foo decides it is holding)

  `tap-next-press` is also a lot like `tap-next`, but decides whether to tap or
  hold based on whether another key is pressed before this one is released.
  Using the minilanguage:
    (tap-next-press x lsft)
  Then:
    Tesc Ta -> xa
    Pa Pesc Ra Resc -> ax (because esc is released before another key is pressed)
    Pesc Pa Resc Ra -> A (because a is pressed before esc is released)
    Pesc Ta Resc    -> A (a is pressed before esc is released here as well)

  These increasingly stranger buttons are, I think, coming from the stubborn
  drive of some of my more eccentric (and I mean that in the most positive way)
  users to make typing with modifiers on the home-row more comfortable.
  Especially layouts that encourage a lot of rolling motions are nicer to use
  with the `release` style buttons.

  The `tap-hold-next-release` (notice a trend?) is just like `tap-next-release`,
  but it comes with an additional timeout that, just like `tap-hold-next` will
  jump into holding-mode after a timeout.

  I honestly think that `tap-hold-next-release`, although it seems the most
  complicated, probably is the most comfortable to use. But I've put all of them
  in a testing layer down below, so give them a go and see what is nice.

  -------------------------------------------------------------------------- |#


(defalias
  xtn (tap-next x lsft)         ;; Shift that does 'x' on tap
  xth (tap-hold 400 x lsft)     ;; Long delay for easier testing
  thn (tap-hold-next 400 x lsft)
  tnr (tap-next-release x lsft)
  tnp (tap-next-press x lsft)
  tnh (tap-hold-next-release 2000 x lsft)

  ;; Used it the colemak layer
  xcp (tap-hold-next 400 esc ctl)
)

;; Some of the buttons used here are defined in the next section
(deflayer multi-overlay
  @mt  _    _    _    _    _    _    _    _    _    _    _    @rem _
  _    _    _    _    _    _    _    _    _    _    _    _    _    _
  @thn _    _    _    _    _    _    _    _    _    _    _    _
  @xtn _    _    _    _    _    _    _    _    _    _    @xth
  @tnr @tnp _              _              _    _    _    @tnh
)


#| --------------------------------------------------------------------------
                              Optional: Multi-tap

  Besides the tap-hold style buttons there is another multi-use button (with.
  only 1 variant, at the moment). The `multi-tap`.

  A `multi-tap` codes for different buttons depending on how often it is tapped.
  It is defined by a series of delays and buttons, followed by a last button
  without delay. As long as you tap the `multi-tap` within the delay specified,
  it will jump to the next button. Once the delay is exceeded the selected
  button is pressed. If the last button in the list is reached, it is
  immediately pressed. When another key is pressed down while we're tapping,
  `multi-tap' also immediately exits and taps the current button.

  Note that you can actually hold the button, so in the below example, going:
  tap-tap-hold (wait 300ms) will get you a pressed c, until you release again.

  -------------------------------------------------------------------------- |#

(defalias
  mt  (multi-tap 300 a 300 b 300 c 300 d e))


#| --------------------------------------------------------------------------
                              Optional: Around-next

  The `around-next` function creates a button that primes KMonad to perform the
  next button-press inside some context. This could be the context of 'having
  Shift pressed' or 'being inside some layer' or, less usefully, 'having d
  pressed'. It is a more general and powerful version of `layer-next`.

  There is also an `around-next-timeout` button that does the same thing as
  `around-next`, except that if some other button press is not detected within
  some timeout, some other button is tapped. This can be used to create a
  leader-key that simply times out (by passing a non-button), or a key that can
  still function as a normal key, but also as a leader key when used slowly.

  I think expansion of this button-style is probably the future of leader-key,
  hydra-style functionality support in KMonad.

  -------------------------------------------------------------------------- |#

(defalias
  ns  (around-next sft)  ;; Shift the next press
  nnm (around-next @num) ;; Perform next press in numbers layer
  ntm (around-next-timeout 500 sft XX)


)

(deflayer around-next-test
  _    _    _    _    _    _    _    _    _    _    _    _    _    _
  _    _    _    _    _    _    _    _    _    _    _    _    _    _
  @ns  _    _    _    _    _    _    _    _    _    _    _    _
  @nnm _    _    _    _    _    _    _    _    _    _    _
  @ntm _    _              _              _    _    _    _
)

#| --------------------------------------------------------------------------
                        Optional: Compose-key sequences

  Compose-key sequences are series of button-presses that your operating system
  will interpret as the insertion of a special character, like accented
  characters, or various special-languages. In that sense, they are just
  syntactic sugar for keyboard macros.

  To get this to work on Linux you will need to set your compose-key with a tool
  like `setxkbmap', as well as tell KMonad that information. See the `defcfg'
  block at the top of this file for a working example. Note that you need to
  wait ever so slightly for the keyboard to register with linux before the
  command gets executed, that's why the `sleep 1`. Also, note that all the
  `/run/current-system' stuff is because the author uses NixOS. Just find a
  shell-command that will:

    1. Sleep a moment
    2. Set the compose-key to your desired key

  Please be aware that what `setxkbmap' calls the `menu' key is not actually the
  `menu' key! If you want to use the often suggested

      setxkbmap -option compose:menu

  you will have to set your compose key within KMonad to `compose' and not
  `menu'.

  After this, this should work out of the box under Linux. Windows does not
  recognize the same compose-key sequences, but WinCompose will make most of the
  sequences line up with KMonad: http://wincompose.info/
  This has not in any way been tested on Mac.

  In addition to hard-coded symbols, we also provide 'uncompleted' macros. Since
  a compose-key sequence is literally just a series of keystrokes, we can omit
  the last one, and enter the sequence for 'add an umlaut' and let the user then
  press some letter to add this umlaut to. These are created using the `+"`
  syntax.

  -------------------------------------------------------------------------- |#

(defalias
  sym (layer-toggle symbols)

)

(deflayer symbols
  _    _    _    _    _    _    _    _    _    _    _    _    _    _
  _    ä    é    ©    _    _    _    _    _    _    _    _    _    _
  _    +'   +~   +`   +^   _    _    _    _    _    _    _    _
  _    +"   +,   _    _    _    _    _    _    _    _    _
  _    _    _              _              _    _    _    _)


#| --------------------------------------------------------------------------
                        Optional: Command buttons

  Currently we also provide the ability to launch arbitrary shell-commands from
  inside KMonad. These commands are simply handed off to the command-shell
  without any further checking or waiting.

  NOTE: currently only tested on Linux, but should work on any platform, as long
  as the command is valid for that platform.

  The `cmd-button' function takes two arguments, the second one of which is
  optional. These represent the commands to be executed on pressing and
  releasing the button respectively.

  BEWARE: never run anyone's configuration without looking at it. You wouldn't
  want to push:

    (cmd-button "rm -rf ~/*") ;; Delete all this user's data


  -------------------------------------------------------------------------- |#

(defalias
  dat (cmd-button "date >> /tmp/kmonad_example.txt")   ;; Append date to tmpfile
  pth (cmd-button "echo $PATH > /tmp/kmonad_path.txt") ;; Write out PATH
  ;; `dat' on press and `pth' on release
  bth (cmd-button "date >> /tmp/kmonad_example.txt"
                  "echo $PATH > /tmp/kmonad_path.txt")
)

(deflayer command-test
  _    _    _    _    _    _    _    _    _    _    _    _    _    _
  _    _    _    _    _    _    _    _    _    _    _    _    _    _
  _    _    _    _    _    _    _    _    _    _    _    _    _
  _    _    _    _    _    _    _    _    _    @dat @pth _
  _    _    _              _              _    _    _    _
)
