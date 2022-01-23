//
//  CustomDefines.h
//  WebRTCExample
//
//  Created by rcadmin on 2022/1/23.
//

#ifndef CustomDefines_h
#define CustomDefines_h

# define DLog(fmt, ...) NSLog((@"[File:%s]\n" "[Method:%s]\n" "[Line:%d] \n" fmt), __FILE__, __FUNCTION__, __LINE__, ##__VA_ARGS__);

#endif /* CustomDefines_h */
