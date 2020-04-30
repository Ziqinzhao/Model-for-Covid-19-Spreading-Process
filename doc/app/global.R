library(tidyverse)
library(ggplot2)
library(gganimate)
library(magick)
library(proxy)

my_theme = theme_light() + theme(plot.title = element_text(hjust = 0.5), plot.subtitle = element_text(hjust = 0.5))

########## Step 0:

# N: Total number of points
# R: A vector of radius
# P: A vector of the proportion of points in each ring area
# Time: The number of days (running times)
# pc: Probability of being infected
# pr: Probability of being attracted by the restaurant
# transform_probability: A data frame contains the probability of symptom changes
# min_infection_range: A number indicates the minimum range of infection
# speed: A vector of movement speed of points with different symptoms
# Num_public: A number indicates the number of public places
# Hospital_capacity: A decimal indicates the ratio of hospital capacity


N = 3000
# R need to be decreasing
R = c(40,30,20,10)
# P should be the value corresponding to R
P = c(1,2,3,4)
Times = 60
pc = 0.1
pr = 0.4
transform_probability = data.frame(ease = c(0.2,0.15,0.1), worsen = c(0.3,0.5,0.8))
rownames(transform_probability) = 3:5
min_infection_range = 1e-2
speed = c(1, 1, 0.8, 0.3, 0.1, 0, 1)
Num_public = 20
Hospital_capacity = 0.01

calculate_alpha = function(N, R, P, c){
  # N: Total number of points
  # R: A vector of radius
  # P: A vector of the proportion of points in each ring area
  # c: Correction coefficient
  
  L = length(R)
  population = P/sum(P)*N
  S = R^2
  area = S - c(S[2:L],0)
  density = population/area
  ratio = density / c(0, density[1:(L-1)])
  alpha = 1/ratio*c
  
  return(alpha)
}

# alpha: A vector of probability of being able to get out of the wall

# alpha should be the value corresponding to R
# This 1.25 is calculate by whole_data when only calculate step 1 to 4
# To let the number of points in each ring after 300 runnings is still the same 
alpha = calculate_alpha(N, R, P, 1.25)

########## Step 0 

generate_gif = function(whole_data, data_public, Times, file){
  # whole_data: A data.frame contains X, Y, Condition and Time
  # data_public: A data frame contains X, Y, class and condition.
  
  data_public$Class = factor(data_public$Class, levels = 1:4, labels = c('Hospital', 'Station', 'Restaurant', 'Hotel'))
  
  p = whole_data %>% 
    ggplot(aes(x = X, y = Y, color = factor(Condition, levels = 1:7), group = 1L)) + 
    geom_point(size = 0.1, alpha = 0.6) + 
    geom_point(data = data_public, aes(x = X, y = Y, size = log(Capacity), color = Class), alpha = 0.8) + 
    scale_color_manual(values = c('1' = '#00CC00', '2' = '#FFCC00', '3' = '#FF69B4', '4' = '#DC143C', '5' = '#8B0000', '6' = '#000000', '7' = '#00CCFF', 'Hospital' = '#FF0000', 'Station' = '#FF6600', 'Restaurant' = '#7FFFD4', 'Hotel' = '#CC99CC'), labels = c('Healthy', 'Incubation', 'Moderate', 'Severe', 'Cirtical', 'Death', 'Cure', 'Hospital', 'Station', 'Restaurant', 'Hotel'), name = 'Condition') +
    scale_size(range = c(2,3.5), name = 'Capacity', guide = FALSE) + 
    coord_fixed() + 
    transition_time(Time) + 
    ease_aes('linear') + 
    my_theme
  
  
  image <- animate(p, fps = 10, nframes = Times * 4)
  image_write(image, file)
}


########## Step 1

random_point_circle = function(R, N, x_center = 0, y_center = 0){
  # R: Radiu
  # N: Number of points
  
  if(length(R) != 1)
    stop('Length of R is not 1 in random_point_circle!')
  if(length(N) != 1)
    stop('Length of N is not 1 in random_point_circle!')
  if(N == 0)
    return(data.frame(X = NULL, Y = NULL))
  
  U = runif(N, 0, R^2)
  A = runif(N, 0 ,2*pi)
  X = sqrt(U)*cos(A) + x_center
  Y = sqrt(U)*sin(A) + y_center
  return(data.frame(X = X, Y = Y))
}

intialize_points = function(N, R, P){
  # N: Total number of points
  # R: A vector of radius
  # P: A vector of the proportion of points in each ring area
  
  if(length(N) != 1)
    stop('Length of N is not 1 in intialize_points!')
  if(length(R) != length(P))
    stop('R and P have different length in intialize_points!')
  if(length(R) == 0)
    stop('Length of R is 0 in intialize_points!')
  
  L = length(R)
  S = R^2
  
  S = S/sum(S)
  P = P/sum(P)
  
  if(mean(P/S == sort(P/S)) != 1)
    stop('The proportion of area is not increasing in intialize_points!')
  
  data = data.frame(X = NULL, Y = NULL)
  
  number_of_points = rep(0, L)
  for(i in 1:L){
    total_area = S[i]
    if(i == L){
      current_area = S[i]
    } else{
      current_area = S[i]-S[i+1]
    }
    need_points = P[i]*N - number_of_points[i]
    generate_points = round(need_points / current_area * total_area)
    data = rbind(data, random_point_circle(R[i],  generate_points))
    if(i == L){
      number_of_points[L] = number_of_points[L] + generate_points 
    } else{
      number_of_points[i:L] = number_of_points[i:L] + round((S[i:L] - c(S[(i+1):L],0)) / total_area * generate_points)
    }
    
  }
  if(nrow(data)<N)
    data = rbind(data, random_point_circle(R[1], N-nrow(data)))
  else
    data = data[1:N,]
  
  
  return(list(data, number_of_points))
}

########## Step 2

plot_points = function(data, condition, data_public){
  # data: A data frame contains X and Y in first 2 column
  # condition: A vector contains 7 factors of illness and its duration
  # data_public: A data frame contains X, Y, class and condition.
  
  if(nrow(data) != nrow(condition))
    stop('Wrong nrow of condition in plot_points!')
  
  data_public$Class = factor(data_public$Class, levels = 1:4, labels = c('Hospital', 'Station', 'Restaurant', 'Hotel'))
  
  t = tibble(X = data$X, Y = data$Y, condition = factor(condition$condition, levels = 1:7))
  g = t %>%
    ggplot(aes(x = X, y = Y, color = condition)) + 
    geom_point(size = 0.1, alpha = 0.6) + 
    geom_point(data = data_public, aes(x = X, y = Y, size = log(Capacity), color = Class), alpha = 0.8) + 
    scale_color_manual(values = c('1' = '#00CC00', '2' = '#FFCC00', '3' = '#FF69B4', '4' = '#DC143C', '5' = '#8B0000', '6' = '#000000', '7' = '#00CCFF', 'Hospital' = '#FF0000', 'Station' = '#FF6600', 'Restaurant' = '#7FFFD4', 'Hotel' = '#CC99CC'), labels = c('Healthy', 'Incubation', 'Moderate', 'Severe', 'Cirtical', 'Death', 'Cure', 'Hospital', 'Station', 'Restaurant', 'Hotel'), name = 'Condition') +
    scale_size(range = c(2,3.5), name = 'Capacity', guide = FALSE) + 
    scale_x_continuous(limits = c(-45, 45)) + 
    scale_y_continuous(limits = c(-45, 45)) +
    coord_fixed() + 
    my_theme
  g
}

########## Step 3

random_walk = function(data, v){
  # data: A data frame contains X and Y in first 2 column
  # v: A vector contains the speed of points
  
  N = nrow(data)
  if(N != length(v %>% unlist)){
    print(N)
    print(length(v %>% unlist))
    stop('Wrong nrow of v in Random_Walk!')
  }
    
  
  distance = rnorm(N, v, sd = v/1.5)
  distance[distance < 0] = 0
  
  A = runif(N, 0 ,2*pi)
  data$X = data$X + distance * cos(A)
  data$Y = data$Y + distance * sin(A)
  
  return(data)
}

########## Step 4

through_wall = function(last_data, new_data, R, alpha, x_center = 0, y_center = 0){
  # last_data: A data frame contains X and Y which is last position
  # new_data: A data frame contains X and Y which is new position
  # R: A vector of radius
  # alpha: A vector of probability of being able to get out of the wall
  
  last_R = sqrt((last_data$X-x_center)^2 + (last_data$Y-y_center)^2)
  new_R = sqrt((new_data$X-x_center)^2 + (new_data$Y-y_center)^2)
  
  R0 = c(Inf, R, 0)
  last_R0 = cut(last_R, breaks = R0, labels = (length(R)+1):1) %>% as.numeric()
  new_R0 = cut(new_R, breaks = R0, labels = (length(R)+1):1) %>% as.numeric()
  
  # wall_level: for example, R = c(40,30,20,10)
  # 1. R<10
  # 2. 10<R<20
  # 3. 20<R<30
  # 4. 30<R<40
  # 5. R>40
  
  index = which(last_R0 < new_R0)
  wall_level = last_R0[index]
  
  # To make sure alpha[1] is the wall_level 1's probability
  alpha0 = rev(alpha)
  alpha_all = alpha0[wall_level]
  
  U = runif(length(index), 0 ,1)
  
  index_run = which(U > alpha_all)
  wall_level_run = wall_level[index_run]
  index_run = index[index_run]
  
  distance = new_data[index_run,c('X', 'Y')] - last_data[index_run,c('X', 'Y')]
  distance = sqrt(distance$X^2 + distance$Y^2)
  
  R1 = last_R[index_run]
  R2 = new_R[index_run]
  rest_distance = distance/(R1+R2)*R2
  
  ratio = (1-2*rest_distance/new_R[index_run])
  ratio = ifelse(ratio < -0.5, -0.5, ratio)
  
  length_run = length(index_run)
  center = data.frame(X = rep(x_center, length_run), Y = rep(y_center, length_run))
  new_data[index_run,] = (new_data[index_run,]-center) * ratio + center
  
  return(new_data)
}

########## Step 5

initialize_infector = function(condition, n){
  # condition: A vector contains 7 factors of illness and its duration
  # n : Number of infectors in first day
  
  index = sample(1:nrow(condition), n, replace = FALSE)
  condition[index, 1] = 2
  
  return(condition)
}

pairwise_dist = function(data1, data2){
  # data1: A data frame contains X and Y which is the position
  # data2: A data frame contains X and Y which is the position
  
  Dist_matrix = as.matrix(proxy::dist(data1, data2))
  
  return(Dist_matrix)
}

infection = function(data, v, condition, infectious_ability, protection_ability){
  # data: A data frame contains X and Y which is the position
  # v: A vector contains the speed of points
  # condition: A vector contains 7 factors of illness and its duration
  
  incubation_infection = ifelse(condition$duration > 3, 1, 0)
  incubation_index = which(condition$condition == 2)
  
  # Condition infection speed
  # 1: Healthy, 0
  # 2: Incubation period, 1 if duration > 3, 0 else
  # 3: Moderate, 1
  # 4: Severe, 1.5
  # 5: Cirtical, 2
  # 6: Death, 0
  # 7: Cure, 0
  
  infection_speed = sapply(condition$condition, function(x) switch(x, '1' = 0,'2' = 1, '3' = 1, '4' = 1.5, '5' = 2, '6' = 0, '7' =  0))
  infection_speed[incubation_index] = infection_speed[incubation_index] * incubation_infection[incubation_index]
  
  infection_index = which(infection_speed > 0)
  infection_length = length(infection_index)
  canbe_infected_index = which(condition$condition == 1)
  canbe_infected_length = length(canbe_infected_index)
  

  if(infection_length == 0)
    return(condition)
  
  distance = pairwise_dist(data[infection_index,], data[canbe_infected_index,])
  
  infection_change = function(condition2,infectious_ability2, protection_ability2, pc, infection_radius){
    
    infection_radius = v[infection_index] * infection_speed[infection_index] * infectious_ability2[infection_index] * protection_ability2[infection_index] * infection_radius + min_infection_range
    infection_radius = matrix(rep(infection_radius, canbe_infected_length), nr = infection_length)
    
    possible_infection = which(distance<infection_radius, arr.ind = TRUE)
    possible_infection = possible_infection[,2] %>% unique()
    
    U = runif(length(possible_infection), 0, 1)
    
    protect_value = protection_ability2[colnames(distance)[possible_infection] %>% as.numeric()]
    confirmed_infection = possible_infection[U < pc * protect_value]
    confirmed_infection = colnames(distance)[confirmed_infection] %>% as.numeric()
    
    condition2[confirmed_infection, ] = data.frame(condition = 2, duration = 0)
    
    return(condition2)
  }
  
  condition = infection_change(condition, infectious_ability, protection_ability, pc, 1)
  condition = infection_change(condition, infectious_ability, protection_ability, pc/4, 2)
  
  return(condition)
}

########## Step 6

symptom_change = function(condition, v, new_condition, new_v, now, ease, worsen, nochange_day = 3){
  index = which(condition$condition == now & condition$duration > nochange_day)
  l = length(index)
  
  U = runif(l, 0 ,1)
  ease_index = index[U < transform_probability[as.character(now),1]]
  worsen_index = index[U > 1-transform_probability[as.character(now),2]]
  
  new_condition[ease_index,] = data.frame(condition = ease, duration = 0)
  new_condition[worsen_index,] = data.frame(condition = worsen, duration = 0)
  new_v[ease_index] = v[ease_index] * speed[ease]/speed[now]
  new_v[worsen_index] = v[worsen_index] * speed[worsen]/speed[now]
  
  return(list(new_condition, new_v))
}

condition_change = function(condition, v, transform_probability, speed){
  # condition: A vector contains 7 factors of illness and its duration
  # v: A vector contains the speed of points
  # transform_probability: A data frame contains the probability of symptom changes
  # speed: A vector of movement speed of points with different symptoms
  
  new_condition = condition
  new_v = v
  
  # End of incubation period, condition 2->3
  incubation_index = which(condition$condition == 2)
  incubation_length = length(incubation_index)
  
  U = rnorm(incubation_length, 7, 2)
  symptom_date = ifelse(U < 3 ,3, U)
  symptom_index = incubation_index[condition$duration[incubation_index] > symptom_date]
  
  new_condition[symptom_index,] = data.frame(condition = 3, duration = 0)
  new_v[symptom_index] = v[symptom_index] * speed[3]/speed[2]
  
  # End of a symptom period, condition 3,4,5 -> (7,4) (3,5) (4,6)
  temp = symptom_change(condition, v, new_condition, new_v, 3, 7, 4)
  new_condition = temp[[1]]
  new_v = temp[[2]]
  
  temp = symptom_change(condition, v, new_condition, new_v, 4, 3, 5)
  new_condition = temp[[1]]
  new_v = temp[[2]]
  
  temp = symptom_change(condition, v, new_condition, new_v, 5, 6, 4)
  new_condition = temp[[1]]
  new_v = temp[[2]]
  
  return(list(new_condition, new_v))
}

########## Step 7

random_public_place = function(R, class, capacity, x_center = 0, y_center = 0){
  # R: Radiu
  # class: A number indicates the category of public_place
  # capacity: A number indicates the number of maximum points in this place
  
  if(length(R) != 1)
    stop('Length of R is not 1 in random_public_place!')
  if(!class %in% 1:4)
    stop('Class is not right in random_public_place!')
  if(capacity <= 0)
    stop('Capacity is not right in random_public_place!')
  
  # class:
  # 1: Hospital, To increase the probability of healing
  # 2: Train Station: To let people leave and come
  # 3: Restaurant/School/Supermarket: Crowded locations
  # 4：Hotel: To quarantine close contacts
  
  A = runif(1, 0 ,2*pi)
  X = R*cos(A) + x_center
  Y = R*sin(A) + y_center
  return(data.frame(X = X, Y = Y, Class = class, Capacity = capacity))
}

intialize_public_place = function(R, P, N, Num_public, Hospital_capacity){
  # N: Total number of points
  # R: A vector of radius
  # P: A vector of the proportion of points in each ring area
  # Num_public: A number indicates the number of public places
  # Hospital_capacity: A decimal indicates the ratio of hospital capacity
  
  if(Num_public < 2)
    stop('The number of public place is too less in intialize_public_place!')
  if(Hospital_capacity > 1 | Hospital_capacity < 0)
    stop('The capacity of hospital is wrong in intialize_public_place!')
  
  data_public = data.frame(X = NULL, Y = NULL, Class = NULL, Capacity = NULL)
  
  L = length(R)
  population = P/sum(P)*N
  S = R^2
  area = S - c(S[2:L],0)
  density = population/area
  density = density/sum(density)
  density_cumsum = c(0, cumsum(density))
  
  U = runif(1, 0, 1)
  data_station = random_public_place((R[L-2] - R[L])*U + R[L], 2, N/100)
  data_public = rbind(data_public, data_station)
  
  num_hospital = ceiling((Num_public-1)/6)
  num_hotel = round((Num_public-1)/3)
  num_school = Num_public - 1 - num_hospital - num_hotel
  
  build_public = function(class2, capacity2, num2){
    
    data_public2 = data.frame(X = NULL, Y = NULL, Class = NULL, Capacity = NULL)
    
    capacity_num = capacity2/num2
    capacity_num = rnorm(num2, capacity_num, capacity_num/3)
    capacity_num[capacity_num<1] = 1
    capacity_num = round(capacity_num)
    
    U = runif(num2, 0 ,1)
    pos = sapply(U, function(x) mean(x>density_cumsum)*(L+1))
    
    U = runif(num2, 0 ,1)
    for(i in 1:num2){
      R0 = c(R, 0)
      R_i = (R0[pos[i]] - R0[pos[i]+1])*U[i] + R0[pos[i]+1]
      data_place = random_public_place(R_i, class2, capacity_num[i])
      data_public2 = rbind(data_public2, data_place)
    }
    return(data_public2)
  }
  
  data_hospital = build_public(1, N*Hospital_capacity, num_hospital)
  data_school = build_public(3, N*Hospital_capacity*10, num_school)
  data_hotel = build_public(4, N*Hospital_capacity*3, num_hotel)
  
  data_public = rbind(data_public, data_hospital)
  data_public = rbind(data_public, data_school)
  data_public = rbind(data_public, data_hotel)
  
  data_public = cbind(data_public, Current = 0, Index = 1:nrow(data_public))
  
  return(data_public)
}

######## Step 8

moveto_restaurant = function(last_data, new_data, data_public, people_duration, before_place_info, v, condition){
  # last_data: A data frame contains X and Y which is last position
  # new_data: A data frame contains X and Y which is new position
  # data_public: A data frame contains X, Y, class and condition.
  # people_duration: A data frame contains each points' place and duration
  # before_place_info: A data frame contains info of points before move to place.
  # v: A vector contains the speed of points
  # condition: A vector contains 7 factors of illness and its duration
  
  data_public2 = data_public %>% filter(Class == 3)
  
  n_public = nrow(data_public2)
  N = nrow(last_data)
  
  distance = pairwise_dist(last_data, data_public2[,c('X', 'Y')])
  
  influence_dist = matrix(rep(v*3, n_public), nc = n_public)
  influence_index = which(distance<influence_dist, arr.ind = TRUE)
  
  possible_index = which(people_duration$place == 0 & people_duration$duration > 4)
  influence_index = influence_index[influence_index[, 1] %in% possible_index,]
  influence_index = matrix(influence_index, nc = 2)
  
  if(nrow(influence_index) == 0)
    return(list(new_data, before_place_info, v, data_public, people_duration))
  
  U = runif(nrow(influence_index), 0, 1)
  
  confirmed_index = influence_index[U < pr,]
  notdupli = !duplicated(confirmed_index[,1])
  cr = confirmed_index[notdupli,1]
  cc = confirmed_index[notdupli,2]
  
  rest_capacity = data_public2[unique(cc),]$Capacity - data_public2[unique(cc),]$Current
  need_capacity = table(cc)
  
  min_capacity = sapply(1:length(unique(cc)),function(x) min(rest_capacity[x], need_capacity[x]))
  permision = sapply(1:length(unique(cc)), function(x) c(rep(TRUE, min_capacity[x]), rep(FALSE, max(need_capacity[x]-min_capacity[x], 0)))) %>% unlist()
  
  data_public2[unique(cc), 'Current'] = data_public2[unique(cc), 'Current'] + min_capacity
  
  cr = cr[permision]
  cc = cc[permision]
  
  before_info = data.frame(index = cr, X = new_data[cr, 'X'], Y = new_data[cr, 'Y'], v = v[cr], condition = condition$condition[cr])
  before_place_info = rbind(before_place_info, before_info)
  
  d =  data_public2[cc, c('X', 'Y')]
  rownames(d) = cr
  
  new_data[cr, ] = d
  v[cr] = 0
  data_public[data_public$Class == 3,] = data_public2
  people_duration[cr,] = data.frame(place = rep(3, length(cr)), place_index = data_public2[cc, 'Index'] ,duration = rep(0, length(cr)))
  
  return(list(new_data, before_place_info, v, data_public, people_duration))
}

######### Step 9

outof_restaurant = function(data, data_public, people_duration, before_place_info, v, condition){
  # data: A data frame contains X and Y 
  # data_public: A data frame contains X, Y, class and condition.
  # people_duration: A data frame contains each points' place and duration
  # before_place_info: A data frame contains info of points before move to place.
  # v: A vector contains the speed of points
  # condition: A vector contains 7 factors of illness and its duration
  
  in_restaurant_index = which(people_duration$place == 3)
  possible_out_index = in_restaurant_index[people_duration[in_restaurant_index, 'duration'] > 3]
  
  num_index = length(possible_out_index)
  
  if(num_index == 0)
    return(list(data, before_place_info, v, data_public, people_duration))
  
  U = runif(num_index, 0, 1)
  confirmed_out_index = possible_out_index[U < pr]
  
  d = before_place_info %>% filter(index %in% confirmed_out_index) %>% arrange(index)
  
  data[confirmed_out_index,] = d[, c('X', 'Y')]
  
  v[confirmed_out_index] = d[, 'v'] * speed[condition$condition[confirmed_out_index]] / speed[d$condition]
  
  out_num = people_duration[confirmed_out_index,]$place_index %>% table()
  reduce_index = which(data_public$Index %in% names(out_num))
  data_public[reduce_index, 'Current'] = data_public[reduce_index, 'Current'] - out_num
  
  people_duration[confirmed_out_index,] = data.frame(place = 0, place_index = 0, duration = 0)
  
  before_info_delete_index = which(before_place_info$index %in% confirmed_out_index)
  before_place_info = before_place_info[-before_info_delete_index, ]
  
  return(list(data, before_place_info, v, data_public, people_duration))
}















