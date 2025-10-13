# 1.0.0

- Add refetchOnResume to refetch when the app is resumed from background
- Improved mutation API
- Add useQueries hook to fetch multiple queries at once

# 0.1.1

- Added keepPreviousData option to retain (or discard) old data while fetching new data after query key changes

# 0.1.0

- Improve useLifecycleAwareStream to handle initial data & stream changes

# 0.0.12

- Improve useLifecycleAwareStream to handle stream changes

# 0.0.11

- Fix diskspace amount check

## 0.0.10

- Change free disk space dependency

## 0.0.9

- Skip persistence if device is low disk space

## 0.0.8

- Make useQuery lifecycle-aware by pausing and resuming based on app state
- Optimize useQuery hook to return cached data synchronously when available

## 0.0.7

- Fix listener not being passed in to the persister

## 0.0.6

- Fix `skipToken` auto boxing issue

## 0.0.5

- Add `skipToken`

## 0.0.4

- Added `useMutationState` hook

## 0.0.3

- Added `invalidateScope` method to `QueryClient`

## 0.0.2

- Improved test coverage
- Added more documentation
- Renamed some classes

## 0.0.1

- First usable release of `volt` package

## 0.0.0

- Initial release
