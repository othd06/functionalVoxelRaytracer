This is a software raytracer in Nim that outputs to a .qoi image file.
The code largely adheres to the functional style (although I do make use of loops and mutable variables within functions)
The code is designed to be highly modular (ie, the qoi encoder doesn't care about the reytracer which doesn't care about the material system etc...)
The only dependency (other than std) is weave for multithreading (which can be installed through nimble)
to run simple compile main.nim (there is an output binary in the repo, that probably isn't best practice but oh well... (also, the output image from the binary is there too))
Feel free to look around, experiment, and use however you want, it should be relatively hackable since different interests are relatively well separated (although everything does pretty much need to import helpers)
