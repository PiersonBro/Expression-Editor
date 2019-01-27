#  TODO
* Arrow syntax doesn't work with FDK
* x substitution doesn't work with FDK
* The cache is not always properly flushed. For example:
```
import Fangraphs
let x = Kyle Seager // 84
x // Invalid input
```
```
import MathKit
let x = Kyle Seager // 84
x // 84
```

There are two bugs first we see an intersting case x substituion working with the MathKit library but not the FDK module. 
However this is only happening because when the import statement changes the drive it doesn't flush the cache resulting in weird data corruption.
As we hurtle toward truly complex programs, the importance of persistence only grows. Implementing this feature is another long overdue priority.
Once those tasks are reasonably solved the next step will be to replace the textbased UI with one based on a drag and drop interaction model.
Hopefully this will also avoid some of the ridiculous special casing that is starting to emerge from this current design.

