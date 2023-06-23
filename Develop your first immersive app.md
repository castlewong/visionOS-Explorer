[Link](https://developer.apple.com/wwdc23/10203)

## Create an Xcode project

>Initial scene - allows us to specify the type of the initial scene that's automatically included in the app

**Windows** are designed to present content that is primarily two-dimensional.(Learn more about the window scene type in [[Meet SwiftUI for spatial computing]])
**Volumes** are designed to present primarily 3D content.(Learn more about the volume scene type in [[Take SwiftUI to the next dimension]])

> Immersive Space - gives us opportunity to add a starting point for immersive content to our app

When app activate this scene type, it moves from the Shared Space to a Full Space
To create an immersive experience in the app, SwiftUI offers 3 different styles for scenes:
1. mixed immersion
2. progressive immersion - opens a portal to offer a more immersive experience that doesn't completely remove people from their surroundings, people use digital crown to adjust the size of the portal
3. full immersion - hides passthrough entirely, surrounds people with app's environment, transporting user into a new place
(More on Immersion styles in [[Go beyond the window with SwiftUI]])

> RealityView - allows developer to place Reality content into a SwiftUI view hierarchy

It takes two closures as parameters:
1. a make closure
2. an update closure - optional, but when it's called, it'll be called whenever the SwiftUI state changes(only when the SwiftUI state changes)
More on RealityView and gestures in Session - [[Build spatial experiences with RealityKit]]



## Simulator

Click mouse simulates tap
Holding the click simulates pinch
Clicking and holding buttons/controls on the down-right while moving the mouse or trackpad allows developer to 
look around
pan
orit
move forwards and backwards

Xcode Previews

## RCP - puts 3D content front and center


## Create an immersive scene

ImmersiveSpace uses the inferred position of your feet as the origin of the content
Full Space apps can request additional data - the person using the app will be prompted to approve this request - shared space apps do not have access to this data (More info on additional data available and privacy considerations in [[Session - Meet ARKit for spatial computing]].)

More detail on RCP in [[Session1 - Meet Reality Composer Pro]] and [[Session3 - Work with Reality Composer Pro content in Xcode]]

Target gestures to entities

## Wrap-up

Create an Xcode project

Simulator and Xcode Previews

Reality Composer Pro

Create an immersive scene

Entity targeting