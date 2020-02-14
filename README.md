OpenSpect Test Task (FancyTree)
========================

For the frontend the solution was based on a simple vuejs project.
That decision was made because the CLI it provides make it easy and fast to try things out.
It is very easy to build and serve the application, also using npm is a great helper in order to
download and manage dependencies. It also inits git which makes it great for keeping an eye on the changes, stash them, discard them, play around basically.

The most difficult part this test presented was the integration with the FancyTree.
Besides it is based on jquery, the problem it denotes does not come only from its architecture but its API and documentation.

The documentation is scattered among different pages and it is not clear in many ways.
The place where a good API is missed the most is when it is a requirement to persist the representation of the tree.
This includes adding nodes, removing, renaming (the Tree assumes every node will have a title property which in our case was not, and it shouldn't assume such a thing).

All the notifications about the changes to the three are being handles on the "modifyChild" function as there was not other way pointed out in the documentation
to tackle this task.
It is remarkable that the Tree provides a persist plugin and its sole effect is to persist in local or session storage the current aesthetics aspect of the tree.
Wheter a node is selected, or if it is folded or unfolded, etc. But nothing like I created a new node, removed, dragged, etc.

There were certain things that given the amount of time we had were not possible to create a workaround for. One of those is the ability to drag and drop a branch from the tree and place it elsewhere (meaning in another node).
Another known bug is that when a child is created its parent children count is not updated.

For the communication with the rest api the HTML5 Web Api was used in order to give it a try, so we wouldn't recommend trying this in old browsers.

It would have been desirable to use a better component instead of a single select such as select2 given the amount of options with a better user experience.

We would have used another Tree library for this test althought it looks pretty nice.


For the backend we developed a SaaS with a rest API implemented on symphony as requested.
We had a two layered architecture (controllers for the rest API and repository for the communication with the DB) but it would
have been desirable to have a third layer for the services in the middle to make a better separation of concerns. There could be also
other traversal layers such as for securization, logging, auditing, but those where out of the scope of this test.

The backend was tested in isolation with postman, it would have been preferrable to have the time to implement proper unit tests and documentation as well.
