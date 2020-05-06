# ADS Project 5: Model of virus spreading process

![GIF](output/output.gif)

Term: Spring 2020
+ Team #1
+ Project title: Lorem ipsum dolor sit amet
+ Team members
	+ Shuxin Chen
	+ Junyan Guo
	+ Vikki Sui
	+ Jinxu Xiang
	+ Ziqin Zhao
+ Project summary: In this project, we created a model of infectious virus spreading process. The simulation is mostly based on the model we built, it is just for visualizing the process of how the virus spread out in population, but not a future prediction.
  + We created a city with specified number of people in the city with higher density in the inner city and lower density in the outer side. In order to keep the population density during the random walk process, we built some invisible walls which has some possibility to send people back to the inner side of the wall.
  + We let some people start to carry the virus. Each one has ability of being infected and protecting themselves and the the probability of getting ease and worse are different based on the their health condition. After having these, the virus start to spread out.
  + Next step is to have some public places. We have restaurants, hospitals and transportation stations. For restaurants, people close to restaurant will have some probability of getting into the restaurant and there will be a higher probability of getting infected. The longer people staying in the restaurant, the higher probability they will come out of the restaurant. and higher probability of getting infected in the restaurant. 
  + For hospital, when people start to have the severe symptoms, they will be send to the hospital if there is still space in the hosipital. After getting into hospital, we let some of the people to ease their case and then send cured or dead people out of hospital. For station, it is used for city-wide exchange of people.
  + In our model, there are also some policies, like wearing mask, develop vaccines and close station. This policies will significantly affect the epidemic situation. If the policy is used earlier, the number of deaths can be greatly reduced.
  + Then we built specified number of cities with the same features and the stations will bring the virus from one city to others. 
  + Finally, we put the whole model in shinyapp. So that you can implement the policy, change the infectious ability on any day and save all the previous results as gif.
	
**Contribution statement**: ([default](doc/a_note_on_contributions.md)) All team members contributed equally in all stages of this project. All team members approve our work presented in this GitHub repository including this contributions statement. 

Following [suggestions](http://nicercode.github.io/blog/2013-04-05-projects/) by [RICH FITZJOHN](http://nicercode.github.io/about/#Team) (@richfitz). This folder is orgarnized as follows.

```
proj/
├── lib/
├── data/
├── doc/
├── figs/
└── output/
```

Please see each subfolder for a README file.
