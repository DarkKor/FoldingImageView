FoldingImageView
================

Pretty simple class for nice folding effect.

It is very easy to use my class to create cool effects and nice controls. Just move h. and .m files FoldingImageView to your project and don't forget to include QuartzCore.framework.
Then you can create your FoldingImageView this way in code:

<pre><code>
FoldingImageView *foldingView = [[[FoldingImageView alloc] initWithImage:[UIImage imageNamed:@"yourImage.png"] frame:yourFrame bends:4] autorelease];
[self.view addSubview:foldingView];
</code></pre>

That's all!

And you can fold it by swipes, open and close by methods, setup count of bends, offsets, change image...
Usage is in sample project.
