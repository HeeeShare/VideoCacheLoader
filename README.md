针对AVPlayer的离线缓存、边下边播的AVAssetResourceLoader方案实现。
这里只封装了几个基础功能，代码不难，有兴趣的可以自己添加功能。
用法：\r
    _videoLoader = [[VideoResourceLoaderHandler alloc] initWithVideoUrl:[NSURL URLWithString:self.videoUrl]];\r
    self.playerItem = _videoLoader.playerItem;\r
