* Project: WB Weather
* Created on: May 2020
* Created by: alj
* Edited on: 23 May 2024
* Edited by: jdm
* Stata v.18

* does
	* reads in Nigeria, w2agnsconversion (wave 2 conversion file)
	* adds kilograms, grams, litres, and centilitres to conversion units
	* outputs conversion file ready for combination with wave 2 and wave 3 harvest data

* assumes
	* access to all raw data
	* w2agnsconversion.dta conversion file

* TO DO:
	* complete

* **********************************************************************
* 0 - setup
* **********************************************************************

* define paths
	loc		cnvrt	=	"$data/household_data/nigeria/conversion_files"
	loc 	export	= 	"$data/household_data/nigeria/conversion_files"
	loc 	logout	= 	"$data/household_data/nigeria/logs"

* open log
	cap log close
	log 	using 	"`logout'/harvconv_master_wave_2", append	
	
* **********************************************************************
* 1 - general import and clean up
* **********************************************************************

* import the relevant conversion file
	use 			"`cnvrt'/w2agnsconversion" , clear
	
* rename for matching with harvest files
	rename 			nscode harv_unit
	
* **********************************************************************
* 2 - modify conversion factors - add kilograms
* **********************************************************************

* need to add new observations for a number of crops to faciliate conversion to kilograms  

	tab 			cropcode, nolabel

	set 			obs 2178
	replace 		cropcode = 1010 in 2178
	set 			obs 2179
	replace 		cropcode = 1020 in 2179
	set 			obs 2180
	replace 		cropcode = 1040 in 2180
	set 			obs 2181
	replace 		cropcode = 1050 in 2181
	set 			obs 2182
	replace 		cropcode = 1051 in 2182
	set 			obs 2183
	replace 		cropcode = 1052 in 2183
	set 			obs 2184
	replace 		cropcode = 1053 in 2184
	set 			obs 2185
	replace			cropcode = 1060 in 2185
	set 			obs 2186
	replace 		cropcode = 1061 in 2186
	set 			obs 2187
	replace 		cropcode = 1062 in 2187
	set 			obs 2188
	replace			cropcode = 1070 in 2188
	set 			obs 2189
	replace 		cropcode = 1080 in 2189
	set 			obs 2190
	replace 		cropcode = 1081 in 2190
	set  			obs 2191
	replace 		cropcode = 1082 in 2191
	set  			obs 2192
	replace 		cropcode = 1083 in 2192
	set  			obs 2193
	replace 		cropcode = 1090 in 2193
	set  			obs 2194
	replace 		cropcode = 1091 in 2194
	set  			obs 2195
	replace 		cropcode = 1092 in 2195
	set  			obs 2196
	replace 		cropcode = 1093 in 2196
	set  			obs 2197
	replace 		cropcode = 1100 in 2197
	set  			obs 2198
	replace 		cropcode = 1110 in 2198
	set  			obs 2199
	replace 		cropcode = 1111 in 2199
	set  			obs 2200
	replace 		cropcode = 1112 in 2200
	set  			obs 2201
	replace			cropcode = 1122 in 2201
	set  			obs 2202
	replace			cropcode = 1123 in 2202
	set  			obs 2203
	replace			cropcode = 1124 in 2203
	set  			obs 2204
	replace			cropcode = 2010 in 2204
	set  			obs 2205
	replace			cropcode = 2020 in 2205
	set 			obs 2206
	replace			cropcode = 2030 in 2206
	set  			obs 2207
	replace			cropcode = 2040 in 2207
	set 			obs 2208
	replace			cropcode = 2050 in 2208
	set 			obs 2209
	replace			cropcode = 2060 in 2209
	set 			obs 2210
	replace			cropcode = 2070 in 2210
	set 			obs 2211
	replace			cropcode = 2071 in 2211
	set 			obs 2212
	replace			cropcode = 2080 in 2212
	set 			obs 2213
	replace			cropcode = 2090 in 2213
	set 			obs 2214
	replace			cropcode = 2100 in 2214
	set 			obs 2215
	replace			cropcode = 2101 in 2215
	set 			obs 2216
	replace			cropcode = 2102 in 2216
	set 			obs 2217
	replace			cropcode = 2103 in 2217
	set 			obs 2218
	replace			cropcode = 2110 in 2218
	set 			obs 2219
	replace			cropcode = 2120 in 2219
	set  			obs 2220
	replace			cropcode = 2130 in 2220
	set 			obs 2221
	replace			cropcode = 2140 in 2221
	set 			obs 2222
	replace			cropcode = 2141 in 2222
	set 			obs 2223
	replace			cropcode = 2142 in 2223
	set 			obs 2224
	replace			cropcode = 2143 in 2224
	set 			obs 2225
	replace			cropcode = 2150 in 2225
	set 			obs 2226
	replace			cropcode = 2160 in 2226
	set 			obs 2227
	replace			cropcode = 2170 in 2227
	set 			obs 2228
	replace			cropcode = 2180 in 2228
	set 			obs 2229
	replace			cropcode = 2190 in 2229
	set 			obs 2230
	replace			cropcode = 2191 in 2230
	set 			obs 2231
	replace			cropcode = 2192 in 2231
	set 			obs 2232
	replace			cropcode = 2193 in 2232
	set 			obs 2233
	replace			cropcode = 2194 in 2233
	set 			obs 2234
	replace			cropcode = 2195 in 2234
	set 			obs 2235
	replace			cropcode = 2200 in 2235
	set 			obs 2236
	replace			cropcode = 2210 in 2236
	set 			obs 2237
	replace			cropcode = 2220 in 2237
	set 			obs 2238
	replace			cropcode = 2230 in 2238
	set 			obs 2239
	replace			cropcode = 2240 in 2239
	set 			obs 2240
	replace			cropcode = 2250 in 2240
	set 			obs 2241
	replace			cropcode = 2260 in 2241
	set 			obs 2242
	replace			cropcode = 2270 in 2242
	set 			obs 2243
	replace			cropcode = 2280 in 2243
	set 			obs 2244
	replace			cropcode = 2290 in 2244
	set 			obs 2245
	replace			cropcode = 2291 in 2245
	set 			obs 2246
	replace			cropcode = 3010 in 2246
	set 			obs 2247
	replace			cropcode = 3020 in 2247
	set 			obs 2248
	replace			cropcode = 3021 in 2248
	set 			obs 2249
	replace			cropcode = 3022 in 2249
	set  			obs 2250
	replace			cropcode = 3030 in 2250
	set 			obs 2251
	replace			cropcode = 3040 in 2251
	set 			obs 2252
	replace			cropcode = 3041 in 2252
	set 			obs 2253
	replace			cropcode = 3042 in 2253
	set 			obs 2254
	replace			cropcode = 3050 in 2254
	set 			obs 2255
	replace			cropcode = 3060 in 2255
	set 			obs 2256
	replace			cropcode = 3061 in 2256
	set 			obs 2257
	replace			cropcode = 3062 in 2257
	set 			obs 2258
	replace			cropcode = 3080 in 2258
	set 			obs 2259
	replace			cropcode = 3090 in 2259
	set 			obs 2260
	replace			cropcode = 3100 in 2260
	set 			obs 2261
	replace			cropcode = 3110 in 2261
	set 			obs 2262
	replace			cropcode = 3111 in 2262
	set 			obs 2263
	replace			cropcode = 3112 in 2263
	set 			obs 2264
	replace			cropcode = 3113 in 2264
	set 			obs 2265
	replace			cropcode = 3120 in 2265
	set 			obs 2266
	replace			cropcode = 3130 in 2266
	set 			obs 2267
	replace			cropcode = 3140 in 2267
	set 			obs 2268
	replace			cropcode = 3150 in 2268
	set 			obs 2269
	replace			cropcode = 3160 in 2269
	set 			obs 2270
	replace			cropcode = 3170 in 2270
	set 			obs 2271
	replace			cropcode = 3180 in 2271
	set 			obs 2272
	replace			cropcode = 3181 in 2272
	set 			obs 2273
	replace			cropcode = 3182 in 2273
	set 			obs 2274
	replace			cropcode = 3183 in 2274
	set 			obs 2275
	replace			cropcode = 3184 in 2275
	set 			obs 2276
	replace			cropcode = 3190 in 2276
	set 			obs 2277
	replace			cropcode = 3200 in 2277
	set 			obs 2278
	replace			cropcode = 3210 in 2278
	set 			obs 2279
	replace			cropcode = 3220 in 2279
	set 			obs 2280
	replace			cropcode = 3221 in 2280
	set 			obs 2281
	replace			cropcode = 3230 in 2281
	set 			obs 2282
	replace			cropcode = 3231 in 2282
	set 			obs 2283
	replace			cropcode = 3232 in 2283
	set 			obs 2284
	replace			cropcode = 3240 in 2284
	set 			obs 2285
	replace			cropcode = 3250 in 2285
	set 			obs 2286
	replace			cropcode = 3260 in 2286
	
* create conversion for kilograms, 1 = kilograms
	replace 		harv_unit = 1 in 2178
	*** 1 change made
	replace 		harv_unit = 1 if harv_unit ==. 
	*** 108 changes made
	replace 		conversion = 1 if harv_unit ==1
	*** 109 changes made

* **********************************************************************
* 3 - modify conversion factors - add grams
* **********************************************************************

* need to add new observations for a number of crops to faciliate conversion to grams  

	set 			obs 2287
	replace 		cropcode = 1010 in 2287
	set 			obs 2288
	replace 		cropcode = 1020 in 2288
	set 			obs 2289
	replace 		cropcode = 1040 in 2289
	set 			obs 2290
	replace 		cropcode = 1050 in 2290
	set 			obs 2291
	replace 		cropcode = 1051 in 2291
	set 			obs 2292
	replace 		cropcode = 1052 in 2292
	set 			obs 2293
	replace 		cropcode = 1053 in 2293
	set 			obs 2294
	replace			cropcode = 1060 in 2294
	set 			obs 2295
	replace 		cropcode = 1061 in 2295
	set 			obs 2296
	replace 		cropcode = 1062 in 2296
	set 			obs 2297
	replace			cropcode = 1070 in 2297
	set 			obs 2298
	replace 		cropcode = 1080 in 2298
	set 			obs 2299
	replace 		cropcode = 1081 in 2299
	set  			obs 2300
	replace 		cropcode = 1082 in 2300
	set  			obs 2301
	replace 		cropcode = 1083 in 2301
	set  			obs 2302
	replace 		cropcode = 1090 in 2302
	set  			obs 2303
	replace 		cropcode = 1091 in 2303
	set  			obs 2304
	replace 		cropcode = 1092 in 2304
	set  			obs 2305
	replace 		cropcode = 1093 in 2305
	set  			obs 2306
	replace 		cropcode = 1100 in 2306
	set  			obs 2307
	replace 		cropcode = 1110 in 2307
	set  			obs 2308
	replace 		cropcode = 1111 in 2308
	set  			obs 2309
	replace 		cropcode = 1112 in 2309
	set  			obs 2310
	replace			cropcode = 1122 in 2310
	set  			obs 2311
	replace			cropcode = 1123 in 2311
	set  			obs 2312
	replace			cropcode = 1124 in 2312
	set  			obs 2313
	replace			cropcode = 2010 in 2313
	set  			obs 2314
	replace			cropcode = 2020 in 2314
	set 			obs 2315
	replace			cropcode = 2030 in 2315
	set  			obs 2316
	replace			cropcode = 2040 in 2316
	set 			obs 2317
	replace			cropcode = 2050 in 2317
	set 			obs 2318
	replace			cropcode = 2060 in 2318
	set 			obs 2319
	replace			cropcode = 2070 in 2319
	set 			obs 2320
	replace			cropcode = 2071 in 2320
	set 			obs 2321
	replace			cropcode = 2080 in 2321
	set 			obs 2322
	replace			cropcode = 2090 in 2322
	set 			obs 2323
	replace			cropcode = 2100 in 2323
	set 			obs 2324
	replace			cropcode = 2101 in 2324
	set 			obs 2325
	replace			cropcode = 2102 in 2325
	set 			obs 2326
	replace			cropcode = 2103 in 2326
	set 			obs 2327
	replace			cropcode = 2110 in 2327
	set 			obs 2328
	replace			cropcode = 2120 in 2328
	*accidentally skipped a bunch of numbers ... that's okay, just going to drop
	set  			obs 2339
	replace			cropcode = 2130 in 2339
	set 			obs 2340
	replace			cropcode = 2140 in 2340
	set 			obs 2341
	replace			cropcode = 2141 in 2341
	set 			obs 2342
	replace			cropcode = 2142 in 2342
	set 			obs 2343
	replace			cropcode = 2143 in 2343
	set 			obs 2344
	replace			cropcode = 2150 in 2344
	set 			obs 2345
	replace			cropcode = 2160 in 2345
	set 			obs 2346
	replace			cropcode = 2170 in 2346
	set 			obs 2347
	replace			cropcode = 2180 in 2347
	set 			obs 2348
	replace			cropcode = 2190 in 2348
	set 			obs 2349
	replace			cropcode = 2191 in 2349
	set 			obs 2350
	replace			cropcode = 2192 in 2350
	set 			obs 2351
	replace			cropcode = 2193 in 2351
	set 			obs 2352
	replace			cropcode = 2194 in 2352
	set 			obs 2353
	replace			cropcode = 2195 in 2353
	set 			obs 2354
	replace			cropcode = 2200 in 2354
	set 			obs 2355
	replace			cropcode = 2210 in 2355
	set 			obs 2356
	replace			cropcode = 2220 in 2356
	set 			obs 2357
	replace			cropcode = 2230 in 2357
	set 			obs 2358
	replace			cropcode = 2240 in 2358
	set 			obs 2359
	replace			cropcode = 2250 in 2359
	set 			obs 2360
	replace			cropcode = 2260 in 2360
	set 			obs 2361
	replace			cropcode = 2270 in 2361
	set 			obs 2362
	replace			cropcode = 2280 in 2362
	set 			obs 2363
	replace			cropcode = 2290 in 2363
	set 			obs 2364
	replace			cropcode = 2291 in 2364
	set 			obs 2365
	replace			cropcode = 3010 in 2365
	set 			obs 2366
	replace			cropcode = 3020 in 2366
	set 			obs 2367
	replace			cropcode = 3021 in 2367
	set 			obs 2368
	replace			cropcode = 3022 in 2368
	set  			obs 2369
	replace			cropcode = 3030 in 2369
	set 			obs 2370
	replace			cropcode = 3040 in 2370
	set 			obs 2371
	replace			cropcode = 3041 in 2371
	set 			obs 2372
	replace			cropcode = 3042 in 2372
	set 			obs 2373
	replace			cropcode = 3050 in 2373
	set 			obs 2374
	replace			cropcode = 3060 in 2374
	set 			obs 2375
	replace			cropcode = 3061 in 2375
	set 			obs 2376
	replace			cropcode = 3062 in 2376
	set 			obs 2377
	replace			cropcode = 3080 in 2377
	set 			obs 2378
	replace			cropcode = 3090 in 2378
	set 			obs 2379
	replace			cropcode = 3100 in 2379
	set 			obs 2380
	replace			cropcode = 3110 in 2380
	set 			obs 2381
	replace			cropcode = 3111 in 2381
	set 			obs 2382
	replace			cropcode = 3112 in 2382
	set 			obs 2383
	replace			cropcode = 3113 in 2383
	set 			obs 2384
	replace			cropcode = 3120 in 2384
	set 			obs 2385
	replace			cropcode = 3130 in 2385
	set 			obs 2386
	replace			cropcode = 3140 in 2386
	set 			obs 2387
	replace			cropcode = 3150 in 2387
	set 			obs 2388
	replace			cropcode = 3160 in 2388
	set 			obs 2389
	replace			cropcode = 3170 in 2389
	set 			obs 2390
	replace			cropcode = 3180 in 2390
	set 			obs 2391
	replace			cropcode = 3181 in 2391
	set 			obs 2392
	replace			cropcode = 3182 in 2392
	set 			obs 2393
	replace			cropcode = 3183 in 2393
	set 			obs 2394
	replace			cropcode = 3184 in 2394
	set 			obs 2395
	replace			cropcode = 3190 in 2395
	set 			obs 2396
	replace			cropcode = 3200 in 2396
	set 			obs 2397
	replace			cropcode = 3210 in 2397
	set 			obs 2398
	replace			cropcode = 3220 in 2398
	set 			obs 2399
	replace			cropcode = 3221 in 2399
	set 			obs 2400
	replace			cropcode = 3230 in 2400
	set 			obs 2401
	replace			cropcode = 3231 in 2401
	set 			obs 2402
	replace			cropcode = 3232 in 2402
	set 			obs 2403
	replace			cropcode = 3240 in 2403
	set 			obs 2404
	replace			cropcode = 3250 in 2404
	set 			obs 2405
	replace			cropcode = 3260 in 2405
	
* replace conversion for grams, 2 = grams
	replace 		harv_unit = 2 in 2287
	*** 1 change made
	replace 		harv_unit = 2 if harv_unit ==. 
	*** 227 changes made
	replace 		conversion = 100 if harv_unit ==2
	*** 228 changes made 
	
	drop 			if cropcode == . 

* **********************************************************************
* 4 - modify conversion factors - add litres
* **********************************************************************

* need to add new observations for a number of crops to faciliate conversion to litres  

	set 			obs 2406
	replace 		cropcode = 1010 in 2406
	set 			obs 2407
	replace 		cropcode = 1020 in 2407
	set 			obs 2408
	replace 		cropcode = 1040 in 2408
	set 			obs 2409
	replace 		cropcode = 1050 in 2409
	set 			obs 2410
	replace 		cropcode = 1051 in 2410
	set 			obs 2411
	replace 		cropcode = 1052 in 2411
	set 			obs 2412
	replace 		cropcode = 1053 in 2412
	set 			obs 2413
	replace			cropcode = 1060 in 2413
	set 			obs 2414
	replace 		cropcode = 1061 in 2414
	set 			obs 2415
	replace 		cropcode = 1062 in 2415
	set 			obs 2416
	replace			cropcode = 1070 in 2416
	set 			obs 2417
	replace 		cropcode = 1080 in 2417
	set 			obs 2418
	replace 		cropcode = 1081 in 2418
	set  			obs 2419
	replace 		cropcode = 1082 in 2419
	set  			obs 2420
	replace 		cropcode = 1083 in 2420
	set  			obs 2421
	replace 		cropcode = 1090 in 2421
	set  			obs 2422
	replace 		cropcode = 1091 in 2422
	set  			obs 2423
	replace 		cropcode = 1092 in 2423
	set  			obs 2424
	replace 		cropcode = 1093 in 2424
	set  			obs 2425
	replace 		cropcode = 1100 in 2425
	set  			obs 2426
	replace 		cropcode = 1110 in 2426
	set  			obs 2427
	replace 		cropcode = 1111 in 2427
	set  			obs 2428
	replace 		cropcode = 1112 in 2428
	set  			obs 2429
	replace			cropcode = 1122 in 2429
	set  			obs 2430
	replace			cropcode = 1123 in 2430
	set  			obs 2431
	replace			cropcode = 1124 in 2431
	set  			obs 2432
	replace			cropcode = 2010 in 2432
	set  			obs 2433
	replace			cropcode = 2020 in 2433
	set 			obs 2434
	replace			cropcode = 2030 in 2434
	set  			obs 2435
	replace			cropcode = 2040 in 2435
	set 			obs 2436
	replace			cropcode = 2050 in 2436
	set 			obs 2437
	replace			cropcode = 2060 in 2437
	set 			obs 2438
	replace			cropcode = 2070 in 2438
	set 			obs 2439
	replace			cropcode = 2071 in 2439
	set 			obs 2440
	replace			cropcode = 2080 in 2440
	set 			obs 2441
	replace			cropcode = 2090 in 2441
	set 			obs 2442
	replace			cropcode = 2100 in 2442
	set 			obs 2443
	replace			cropcode = 2101 in 2443
	set 			obs 2444
	replace			cropcode = 2102 in 2444
	set 			obs 2445
	replace			cropcode = 2103 in 2445
	set 			obs 2446
	replace			cropcode = 2110 in 2446
	set 			obs 2447
	replace			cropcode = 2120 in 2447
	set  			obs 2448
	replace			cropcode = 2130 in 2448
	set 			obs 2449
	replace			cropcode = 2140 in 2449
	set 			obs 2450
	replace			cropcode = 2141 in 2450
	set 			obs 2451
	replace			cropcode = 2142 in 2451
	set 			obs 2452
	replace			cropcode = 2143 in 2452
	set 			obs 2453
	replace			cropcode = 2150 in 2453
	set 			obs 2454
	replace			cropcode = 2160 in 2454
	set 			obs 2455
	replace			cropcode = 2170 in 2455
	set 			obs 2456
	replace			cropcode = 2180 in 2456
	set 			obs 2457
	replace			cropcode = 2190 in 2457
	set 			obs 2458
	replace			cropcode = 2191 in 2458
	set 			obs 2459
	replace			cropcode = 2192 in 2459
	set 			obs 2460
	replace			cropcode = 2193 in 2460
	set 			obs 2461
	replace			cropcode = 2194 in 2461
	set 			obs 2462
	replace			cropcode = 2195 in 2462
	set 			obs 2463
	replace			cropcode = 2200 in 2463
	set 			obs 2464
	replace			cropcode = 2210 in 2464
	set 			obs 2465
	replace			cropcode = 2220 in 2465
	set 			obs 2466
	replace			cropcode = 2230 in 2466
	set 			obs 2467
	replace			cropcode = 2240 in 2467
	set 			obs 2468
	replace			cropcode = 2250 in 2468
	set 			obs 2469
	replace			cropcode = 2260 in 2469
	set 			obs 2470
	replace			cropcode = 2270 in 2470
	set 			obs 2471
	replace			cropcode = 2280 in 2471
	set 			obs 2472
	replace			cropcode = 2290 in 2472
	set 			obs 2473
	replace			cropcode = 2291 in 2473
	set 			obs 2474
	replace			cropcode = 3020 in 2474
	set 			obs 2475
	replace			cropcode = 3021 in 2475
	set 			obs 2476
	replace			cropcode = 3022 in 2476
	set  			obs 2477
	replace			cropcode = 3030 in 2477
	set 			obs 2478
	replace			cropcode = 3040 in 2478
	set 			obs 2479
	replace			cropcode = 3041 in 2479
	set 			obs 2480
	replace			cropcode = 3042 in 2480
	set 			obs 2481
	replace			cropcode = 3050 in 2481
	set 			obs 2482
	replace			cropcode = 3060 in 2482
	set 			obs 2483
	replace			cropcode = 3061 in 2483
	set 			obs 2484
	replace			cropcode = 3062 in 2484
	set 			obs 2485
	replace			cropcode = 3080 in 2485
	set 			obs 2486
	replace			cropcode = 3090 in 2486
	set 			obs 2487
	replace			cropcode = 3100 in 2487
	set 			obs 2488
	replace			cropcode = 3110 in 2488
	set 			obs 2489
	replace			cropcode = 3111 in 2489
	set 			obs 2490
	replace			cropcode = 3112 in 2490
	set 			obs 2491
	replace			cropcode = 3113 in 2491
	set 			obs 2492
	replace			cropcode = 3120 in 2492
	set 			obs 2493
	replace			cropcode = 3130 in 2493
	set 			obs 2494
	replace			cropcode = 3140 in 2494
	set 			obs 2495
	replace			cropcode = 3150 in 2495
	set 			obs 2496
	replace			cropcode = 3160 in 2496
	set 			obs 2497
	replace			cropcode = 3170 in 2497
	set 			obs 2498
	replace			cropcode = 3180 in 2498
	set 			obs 2499
	replace			cropcode = 3181 in 2499
	set 			obs 2500
	replace			cropcode = 3182 in 2500
	set 			obs 2501
	replace			cropcode = 3183 in 2501
	set 			obs 2502
	replace			cropcode = 3184 in 2502
	set 			obs 2503
	replace			cropcode = 3190 in 2503
	set 			obs 2504
	replace			cropcode = 3200 in 2504
	set 			obs 2505
	replace			cropcode = 3210 in 2505
	set 			obs 2506
	replace			cropcode = 3220 in 2506
	set 			obs 2507
	replace			cropcode = 3221 in 2507
	set 			obs 2508
	replace			cropcode = 3230 in 2508
	set 			obs 2509
	replace			cropcode = 3231 in 2509
	set 			obs 2510
	replace			cropcode = 3232 in 2510
	set 			obs 2511
	replace			cropcode = 3240 in 2511
	set 			obs 2512
	replace			cropcode = 3250 in 2512
	set 			obs 2513
	replace			cropcode = 3260 in 2513
	set 			obs 2514
	replace			cropcode = 3010 in 2514
	
	
* replace conversion for liters, 3 = liters
	replace 		harv_unit = 3 in 2406
	*** 1 change made
	replace 		harv_unit = 3 if harv_unit ==. 
	*** 227 changes made
	replace 		conversion = 1 if harv_unit ==3
	*** 228 changes made 
	
	drop 			if cropcode == . 
	
* **********************************************************************
* 6 - modify conversion factors - add centilitres 
* **********************************************************************


* need to add new observations for a number of crops to faciliate conversion to litres  

	set 			obs 2515
	replace 		cropcode = 1010 in 2515
	set 			obs 2516
	replace 		cropcode = 1020 in 2516
	set 			obs 2517
	replace 		cropcode = 1040 in 2517
	set 			obs 2518
	replace 		cropcode = 1050 in 2518
	set 			obs 2519
	replace 		cropcode = 1051 in 2519
	set 			obs 2520
	replace 		cropcode = 1052 in 2520
	set 			obs 2521
	replace 		cropcode = 1053 in 2521
	set 			obs 2522
	replace			cropcode = 1060 in 2522
	set 			obs 2523
	replace 		cropcode = 1061 in 2523
	set 			obs 2524
	replace 		cropcode = 1062 in 2524
	set 			obs 2525
	replace			cropcode = 1070 in 2525
	set 			obs 2526
	replace 		cropcode = 1080 in 2526
	set 			obs 2527
	replace 		cropcode = 1081 in 2527
	set  			obs 2528
	replace 		cropcode = 1082 in 2528
	set  			obs 2529
	replace 		cropcode = 1083 in 2529
	set  			obs 2530
	replace 		cropcode = 1090 in 2530
	set  			obs 2531
	replace 		cropcode = 1091 in 2531
	set  			obs 2532
	replace 		cropcode = 1092 in 2532
	set  			obs 2533
	replace 		cropcode = 1093 in 2533
	set  			obs 2534
	replace 		cropcode = 1100 in 2534
	set  			obs 2535
	replace 		cropcode = 1110 in 2535
	set  			obs 2536
	replace 		cropcode = 1111 in 2536
	set  			obs 2537
	replace 		cropcode = 1112 in 2537
	set  			obs 2538
	replace			cropcode = 1122 in 2538
	set  			obs 2539
	replace			cropcode = 1123 in 2539
	set  			obs 2540
	replace			cropcode = 1124 in 2540
	set  			obs 2541
	replace			cropcode = 2010 in 2541
	set  			obs 2542
	replace			cropcode = 2020 in 2542
	set 			obs 2543
	replace			cropcode = 2030 in 2543
	set  			obs 2544
	replace			cropcode = 2040 in 2544
	set 			obs 2545
	replace			cropcode = 2050 in 2545
	set 			obs 2546
	replace			cropcode = 2060 in 2546
	set 			obs 2547
	replace			cropcode = 2070 in 2547
	set 			obs 2548
	replace			cropcode = 2071 in 2548
	set 			obs 2549
	replace			cropcode = 2080 in 2549
	set 			obs 2550
	replace			cropcode = 2090 in 2550
	set 			obs 2551
	replace			cropcode = 2100 in 2551
	set 			obs 2552
	replace			cropcode = 2101 in 2552
	set 			obs 2553
	replace			cropcode = 2102 in 2553
	set 			obs 2554
	replace			cropcode = 2103 in 2554
	set 			obs 2555
	replace			cropcode = 2110 in 2555
	set 			obs 2556
	replace			cropcode = 2120 in 2556
	set  			obs 2557
	replace			cropcode = 2130 in 2557
	set 			obs 2558
	replace			cropcode = 2140 in 2558
	set 			obs 2559
	replace			cropcode = 2141 in 2559
	set 			obs 2560
	replace			cropcode = 2142 in 2560
	set 			obs 2561
	replace			cropcode = 2143 in 2561
	set 			obs 2562
	replace			cropcode = 2150 in 2562
	set 			obs 2563
	replace			cropcode = 2160 in 2563
	set 			obs 2564
	replace			cropcode = 2170 in 2564
	set 			obs 2565
	replace			cropcode = 2180 in 2565
	set 			obs 2566
	replace			cropcode = 2190 in 2566
	set 			obs 2567
	replace			cropcode = 2191 in 2567
	set 			obs 2568
	replace			cropcode = 2192 in 2568
	set 			obs 2569
	replace			cropcode = 2193 in 2569
	set 			obs 2570
	replace			cropcode = 2194 in 2570
	set 			obs 2571
	replace			cropcode = 2195 in 2571
	set 			obs 2572
	replace			cropcode = 2200 in 2572
	set 			obs 2573
	replace			cropcode = 2210 in 2573
	set 			obs 2574
	replace			cropcode = 2220 in 2574
	set 			obs 2575
	replace			cropcode = 2230 in 2575
	set 			obs 2576
	replace			cropcode = 2240 in 2576
	set 			obs 2577
	replace			cropcode = 2250 in 2577
	set 			obs 2578
	replace			cropcode = 2260 in 2578
	set 			obs 2579
	replace			cropcode = 2270 in 2579
	set 			obs 2580
	replace			cropcode = 2280 in 2580
	set 			obs 2581
	replace			cropcode = 2290 in 2581
	set 			obs 2582
	replace			cropcode = 2291 in 2582
	set 			obs 2583
	replace			cropcode = 3020 in 2583
	set 			obs 2584
	replace			cropcode = 3021 in 2584
	set 			obs 2585
	replace			cropcode = 3022 in 2585
	set  			obs 2586
	replace			cropcode = 3030 in 2586
	set 			obs 2587
	replace			cropcode = 3040 in 2587
	set 			obs 2588
	replace			cropcode = 3041 in 2588
	set 			obs 2589
	replace			cropcode = 3042 in 2589
	set 			obs 2590
	replace			cropcode = 3050 in 2590
	set 			obs 2591
	replace			cropcode = 3060 in 2591
	set 			obs 2592
	replace			cropcode = 3062 in 2592
	set 			obs 2593
	replace			cropcode = 3080 in 2593
	set 			obs 2594
	replace			cropcode = 3090 in 2594
	set 			obs 2595
	replace			cropcode = 3100 in 2595
	set 			obs 2596
	replace			cropcode = 3110 in 2596
	set 			obs 2597
	replace			cropcode = 3111 in 2597
	set 			obs 2598
	replace			cropcode = 3112 in 2598
	set 			obs 2599
	replace			cropcode = 3113 in 2599
	set 			obs 2600
	replace			cropcode = 3120 in 2600
	set 			obs 2601
	replace			cropcode = 3130 in 2601
	set 			obs 2602
	replace			cropcode = 3140 in 2602
	set 			obs 2603
	replace			cropcode = 3150 in 2603
	set 			obs 2604
	replace			cropcode = 3160 in 2604
	set 			obs 2605
	replace			cropcode = 3170 in 2605
	set 			obs 2606
	replace			cropcode = 3180 in 2606
	set 			obs 2607
	replace			cropcode = 3181 in 2607
	set 			obs 2608
	replace			cropcode = 3182 in 2608
	set 			obs 2609
	replace			cropcode = 3183 in 2609
	set 			obs 2610
	replace			cropcode = 3184 in 2610
	set 			obs 2611
	replace			cropcode = 3190 in 2611
	set 			obs 2612
	replace			cropcode = 3200 in 2612
	set 			obs 2613
	replace			cropcode = 3210 in 2613
	set 			obs 2614
	replace			cropcode = 3220 in 2614
	set 			obs 2615
	replace			cropcode = 3221 in 2615
	set 			obs 2616
	replace			cropcode = 3230 in 2616
	set 			obs 2617
	replace			cropcode = 3231 in 2617
	set 			obs 2618
	replace			cropcode = 3232 in 2618
	set 			obs 2619
	replace			cropcode = 3240 in 2619
	set 			obs 2620
	replace			cropcode = 3250 in 2620
	set 			obs 2621
	replace			cropcode = 3260 in 2621
	set 			obs 2622
	replace			cropcode = 3010 in 2622
	set 			obs 2623
	replace			cropcode = 3061 in 2623
	
* replace conversion for centiliters, 4 = centiliters
	replace 		harv_unit = 4 in 2515
	*** 1 change made
	replace 		harv_unit = 4 if harv_unit ==. 
	*** 227 changes made
	replace 		conversion = 100 if harv_unit ==4
	*** 228 changes made 
	
	drop 			if cropcode == . 

* **********************************************************************
* 6 - end matter, clean up to save
* **********************************************************************
	drop 			kg
	isid			cropcode harv_unit
	
* create unique household-plot identifier
	sort			cropcode harv_unit
	egen			crop_unit = group(cropcode harv_unit)
	lab var			crop_unit "unique crop and unit identifier"
	
	compress
	describe
	summarize

* save file
	save 			"`export'/harvconv_wave_2.dta", replace

* close the log
	log		close

/* END */
