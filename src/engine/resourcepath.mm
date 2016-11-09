#import <Foundation/Foundation.h>
#include "resourcepath.hpp"

namespace Jumpman {

std::string GetResourcePath() {
  std::string base_path;
  NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
  NSBundle* bundle = [NSBundle mainBundle];

  if (bundle != nil) {
    NSString* path = [bundle resourcePath];
    base_path = [path UTF8String] + std::string("/");
  }

  [pool drain];

  return base_path;
}

};  // namespace Jumpman
