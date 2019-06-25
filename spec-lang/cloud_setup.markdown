# Cloud Setup

We expect many participants to use GPUs to try and speed up the SNARK prover, so we've set up a preconfigured AWS AMI that should help you get started.

1. Go to console.aws.amazon.com

2. Login or create account

3. Choose US West (Oregon) as your region

<img src="static/oregon.png">

4. Type EC2 in the "Find Services" searchbar

<img src="static/ec2.png">

5. Click launch instance

<img src="static/launch.png">

6. Type "snark" in the search bar for AMIs

<img src="static/snark.png">

7. In "Community AMIs," select the coda-snark-challenge-base-* image

<img src="static/ami.png">

8. You should choose a GPU instance -- we recommend choosing a p2.xlarge

<img src="static/p2x.png">

9. Click "review and launch"

You may encounter an error where you aren't allowed to launch an p2.xlarge instance. We've found that requests [here](http://aws.amazon.com/contact-us/ec2-request) are quickly granted.

10. Click launch

<img src="static/launchv2.png">

11. Go to EC2

12. Right click on instance and select "Connect"

<img src="static/connect.png">

13. Follow the instructions to get connected
