---
title: "Transcript: How to Make a Contribution to Base R"
---

*This is a text transcript of the video ["How to Make a Contribution to Base R."](../../index.qmd#quick-start)*

Welcome to this quick demo of how to make a contribution to base R.

R is maintained by the R Core team. Members of the R community can contribute in various ways, for example, analysing and fixing bugs, translating R's messages, warnings, and errors, testing pre-release versions of R, or developing new features. In this demo, we'll focus on bug fixing.

## Finding a bug to work on

First, we need to find a good bug to work on. Bugs in R are tracked in R's Bugzilla, which can be found at bugs.r-project.org. We can browse the bugs by clicking on the Browse button in the top menu. There are two categories to browse. We'll focus on R, which are the bugs in R itself.

This takes you to a list of components, which are categories of bugs that you can look at. Let's take a look at Documentation. This returns a list of bugs that have been categorised as documentation bugs by the bug reporter. We can browse through the summaries to look for bugs that we think we might be able to help with.

Let's take a look at the last one here, "Clarification needed in ?c," which refers to the help file for the `c` function. The top of the bug report shows some basic metadata. If we scroll down, we'll see a description of the bug by the reporter, in this case Michael Chirico. Below that, there may be one or more comments from R Core developers or other contributors.

## What makes a good first issue

A good first issue is one where the next step is clear. The bug report might need a minimal reproducible example to use as a test case. Or the bug might need checking in the development version of R to see if it is still a bug or has already been fixed. Alternatively, the bug might need debugging to diagnose the root cause. Finally, you might contribute to the discussion of how to fix the bug or even propose a patch. It is even better if an R Core member has shown support for one of these things in a comment so you know the next step for sure.

Bug reports that are too new are best avoided, as they are often taken up quickly by experienced contributors. On the other hand, bug reports that are very old often lack consensus on the next step or require a decision to be made by R Core. You should avoid bugs where there is disagreement on the next step or someone else is clearly working on it. Finally, avoid bugs that are clearly outside your area of expertise.

It can take a while to find a good issue to work on, but there are some shortcuts available. You can attend an R Contributor Office Hour, or look on the work-out-loud channel of the R Contributor Slack, where good first issues are sometimes shared. Or you can attend special events like the Bug BBQ, where good first issues are prepared in advance.

## Analysing a bug: an example

One of the hardest tasks is analysing bugs to get to the root of the issue. Let's look at an example, Bug 17863. The bug reporter provided some test code for a one-factor factor analysis. When the print function is called on the resulting test object, various elements of the result are printed as expected, including the call, the uniquenesses, and the loadings.

Before R 4.3.0, when the print function was called with the argument `sort = TRUE`, we get an unexpected result. The loadings are printed as a vector rather than as a matrix, so we lose the row and column labels.

The print function is an S3 generic, so we need to find out which S3 method is being used here. First we use the `class` function to find out that `test` is an object of class `factanal`. If an S3 print method exists for this class, it will be called `print.factanal`. We use the `getAnywhere` function to search for this method. A method is found in the stats package and printed out. In the body of the function we can see the `cat` and `print` calls that print different elements of the `factanal` object. In the fourth line of the function, `print` is called on the loadings element to print the loadings.

So now we repeat this exercise on the loadings element of our test object. We find out that the loadings element is an object of class `loadings`, and there is a `print.loadings` method in the stats package.

If we try running `debugonce` on `stats::print.loadings`, we get an error telling us that `print.loadings` is not exported from the stats package. We can access internal functions by using three colons instead, so `debugonce` runs without error.

Now when we run `print(test, sort = TRUE)`, the call and uniquenesses are printed, but when `print.loadings` is called, we enter a debugging environment. The body of this function is printed out to the console, and at the end we find a browse prompt.

We can press the Enter or Return key to step through the code in the `print.loadings` function, running one line at a time. Here we get to a conditional block that is run if `sort == TRUE`, as in our test case. When we press return, we enter this block and can continue stepping through line by line.

At the end of this block, there is a line where an object `Lambda` is overwritten by an ordered version of itself. Before running this line, we can print `Lambda` with and without the ordering. Here it is with the ordering, and here it is without. Clearly the ordering is changing the structure of the object. We have found the root cause of the issue.

## Fixing the bug

In this case, there is a simple fix. Experienced R programmers may know that when the rows of a one column matrix are indexed, a vector is returned unless we set `drop = FALSE`, as here.

We can check this fix by creating our own version of `print.loadings` with the fix applied. After sourcing our version of `print.loadings` we can test it on the loadings element of our test object. The fix works.

## Proposing the fix to R Core

Once we have a fix, how can we propose it to R Core? If the fix is simple to describe, we can propose it by adding a comment on Bugzilla, as I have done here. To add comments you need a Bugzilla account. See the link for more details.

Alternatively, you can create a patch using the r-svn mirror of the R sources. Find the source file containing the code you want to change. Click the Edit button. This will create a fork of the r-svn repo on your GitHub account and open a window where you can edit the file.

Make the changes in the source file. When you are ready, click the Commit changes button to commit these changes to your fork. A new branch will be created with your changes. Now you will see a Compare and pull request button on your fork. Click this to open a pull request back to the original r-svn repo.

Enter a description of your changes. Here I have written "minor change for demo." If you want, you can add more information in the comment box for people you might ask to review your pull request.

Once you have created a pull request, you will be taken back to the original repo, and you'll see some automated checks starting to run. These build R on different platforms, and run its test suite. If the checks pass, everything in amber here will turn green.

If everything looks good, add `.diff` to the URL for your pull request, and enter the modified URL in your browser. This will generate a diff of your changes. Right-click on the browser window to save this as a `.diff` file. You can then attach the diff file to the bug report on Bugzilla with a comment explaining your proposed fix.

## Wrap-up

This quick demo has run through the basics of contributing to fixing bugs in R. For more information on this and other ways to contribute, refer to the online R Development Guide, attend R Contributor events, or join the Slack group for peer support.

We hope this has inspired you to start contributing to R.
