Apple Response:

```
Guideline 2.1 - Information Needed - New App Submission



We need additional information to better understand the app and complete the review.

Note: Before submitting, run the submitted build through your own testing and quality assurance process on supported physical devices. App Review is intended for apps and metadata that are complete and ready for App Store customers.

If the app is ready for review, follow the directions below.

Next Steps

Reply in App Store Connect with all of the following information and also add this information to the Notes field of the App Review Information section in App Store Connect, for reference on future submissions:

1. A screen recording captured on a physical device, running the latest operating system, demonstrating the app's functionality. The recording must begin with launching the app and show the typical user flow. If the app has any of the following, include them in the recording:

- Account registration, login, and account deletion flows. Account deletion is required in apps that support account creation.
- Any user-generated content, including the required content reporting and blocking mechanisms.

2. A description of the app's purpose and target audience, including the problem it solves and the value it provides
3. Instructions for setting up and accessing the app's main features, including any required login credentials or sample files
4. A list of the external services, tools, or platforms the app uses to deliver its core functionality (for example, data providers, authentication services, payment processors, or AI services)
5. Describe any regional differences in the app’s features or content, or confirm that the app functions consistently across all regions
6. If the app operates in a highly regulated industry or includes protected third-party material, provide any relevant documentation or credentials to demonstrate you are authorized to provide these services or protected material


Prevent Common Issues

- Guideline 2.1 - Bugs and crashes: Apps are reviewed on physical devices to mirror real-world conditions. Test the app on each supported device platform before submitting. Use TestFlight to distribute builds for beta testing on real devices.
- Guideline 2.1 - Accessing the app: If the app includes account-based features, provide up-to-date login credentials for a demo account in App Store Connect. If the app has multiple account types, provide credentials for each type in the Notes field.
- Guideline 2.3.3 - Screenshots: App screenshots on the App Store must show the actual app in use, and not merely the title art, login page, or splash screen.
- Guideline 3.1.1 - In-App Purchase: In-App Purchase products should be configured and submitted alongside the app.
- Guideline 3.2 - Other Business Models: If your app is intended to be used by specific businesses, organizations or employees then use one of the other distribution options available to you through the Apple Developer Program Account.
```

My Response to App Review:

```
Here are my responses to the questions from the first review:

1. I have attached a video showing an example of using the app, including adding measurements to a fresh app install and viewing them in the app.  (There is no account needed for the app, and no account registration, login, or account deletion flow in the app. The app only uses the user's existing iCloud account to sync data between a user's devices, there is no separate sign-in.)
2. The purpose of the app is to track rain measurements recorded from a physical rain gauge. It provides more features than simply tracking them on paper or in a spreadsheet app, including calendar views and statistics views generated from the user's logged measurements.
3. To use the app, the user just needs to start adding measurements with the (+) button. After adding measurements, the Calendar and Stats tabs automatically include them in their views. There is no login needed.
4. The app uses Apple's In-App Purchase for an optional tip jar, and I have set up the In App purchase options as part of this app submission.  The app also uses CloudKit for iCloud syncing of the user's data. There are no other external services, tools, or platforms used by the app.
5. The only regional difference in the app would be allowing the user to select Metric or Imperial units of measurement. Other than that, the app functions the same in all regions.
6. The app does not operate in a regulated industry or use protected third-party material.

I have confirmed the app works by testing on several of my physical devices, including two iPhones and an iPad, and believe it is ready for review.
```



Notes field:

```

```