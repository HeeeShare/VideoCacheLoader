针对AVPlayer的离线缓存、边下边播的AVAssetResourceLoader方案实现。
这里只封装了几个基础功能，代码不难，有兴趣的可以自己添加功能。
用法：
    1. _videoLoader = [[VideoResourceLoaderHandler alloc] initWithVideoUrl:[NSURL URLWithString:self.videoUrl]];
    2. _videoLoader.delegate = self;
    3. self.playerItem = _videoLoader.playerItem;
