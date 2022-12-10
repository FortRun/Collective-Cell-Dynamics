!! ########### Program For Various Geometrical Observables : Time Averaged quantities or multiple ensembles ########

	implicit none
	integer::i,j,jm,l,t,d,k
	integer,parameter::m=256,n=50
	double precision::Kadh
	double precision::x(m,n+1),y(m,n+1),A(m),mean_area(2000),sum_area,area_frac(2000),area_frac_compl,b,t1,t2,sum_mean_area,&
			  & sum_area_frac,timeavg_area(100),timeavg_area_frac(100),sum_timeavg_area,sum_sq_timeavg_area,&
			  & ensavg_area,ensavg_sq_area,std_dev_area,sum_timeavg_area_frac,ensavg_area_frac,&
			  & sum_sq_timeavg_area_frac,ensavg_sq_area_frac,std_dev_area_frac
	double precision::P(m),sum_perimeter,mean_perimeter(2000),sum_mean_perimeter,timeavg_perimeter(100),sum_timeavg_perimeter,&
			  & ensavg_perimeter,sum_sq_timeavg_perimeter,ensavg_sq_perimeter,std_dev_perimeter
	double precision::SI(m),sum_SI,mean_SI(2000),sum_mean_SI,timeavg_SI(100),sum_timeavg_SI,ensavg_SI,&
			  & sum_sq_timeavg_SI,ensavg_sq_SI,std_dev_SI
	double precision,parameter::box = 46.0d0
	character(len=100):: infile,outfile
	character(len=len('With_noise_coord_wrtSysCOM/Adh0.001_P5_vo0.2_sgma0.5_dt0.001/Geometry_related/')):: outpath,inpath,&
														& outpath2
	call cpu_time(t1)
	
	inpath  = 'Var0.2/Kadh0.001/'
	outpath = 'Geometry/'
	outpath2= ''

	Kadh = 0.001d0	

	open(25,file=trim(adjustl(outpath))//'Avg_Geometry_5E6_1ens_high_adh_0.001_var0.2.dat',&
           & status='unknown',position='append',action='write') 
	!open(12,file=trim(adjustl(outpath2))//'Avg_area_frac_with_adh.dat',&
         !  & status='unknown',position='append',action='write')


	jm=1
	sum_timeavg_area=0.0d0
	sum_sq_timeavg_area=0.0d0
	sum_timeavg_perimeter=0.0d0
	sum_sq_timeavg_perimeter=0.0d0
	sum_timeavg_SI=0.0d0
	sum_sq_timeavg_SI=0.0d0
	sum_timeavg_area_frac=0.0d0
	sum_sq_timeavg_area_frac=0.0d0
	do j=1,jm

	write (infile,"('adh0.001_Noise(var0.2_v_0.2)p25_lo0.1_Kspr120_ite_1E7_cnf_',I0,'.dat')") j
	!write (outfile,"('Geometry_adh0.001_1.5_Noise(var0.5_v_0.2)P5_Kspr120_ite_1E7_cnf_',I0,'.dat')") j

	open(10,file=trim(adjustl(inpath))//infile,status='unknown',action='read')
             
	!open(11,file=trim(adjustl(outpath))//outfile,status='unknown',position='append',action='write')
	
	!d=5000
	t = 0
	sum_mean_area=0.0d0
	sum_mean_perimeter=0.0d0
	sum_mean_SI=0.0d0
	sum_area_frac=0.0d0
	do k=1,2001 
		if(k.ge.1001) then  !! data is considered from 5E6 iteration step.
			t=t+1
			sum_area  = 0.0d0
			sum_perimeter = 0.0d0
			sum_SI = 0.0d0
			A=0.0d0
			P=0.0d0
			SI=0.0d0		
			do l=1,m
		    		do i=1,n
					read(10,*)b,b,b,x(l,i),y(l,i)				
				end do
				x(l,n+1) = x(l,1)  !! Periodic boundary in a single cell
		 	        y(l,n+1) = y(l,1)
				do i=1,n
					A(l) = A(l) + 0.5d0*(x(l,i)*y(l,i+1) - x(l,i+1)*y(l,i)) 	 !! Area calculation of l-th cell
					P(l) = P(l) + dsqrt((x(l,i)-x(l,i+1))**2 + (y(l,i)-y(l,i+1))**2) !!Perimeter calculation of l-th cell
				end do
				A(l) = dabs(A(l))
				SI(l) = P(l)/dsqrt(A(l))             !! Shape Index
		  	 	sum_area = sum_area + A(l)           !! Total area of all the cells at time t
				sum_perimeter = sum_perimeter + P(l) !! Total perimeter of all the cells at time t
				sum_SI = sum_SI + SI(l)              !! Total shape-index of all the cells at time t     
			end do
			!if(k.eq.20) write(*,*)A
			area_frac(t) = sum_area/(box*box)
			!area_frac_compl = 1-area_frac !! Complementary of the area-fraction(vacant space fraction)
			mean_area(t) = sum_area/m        !! mean area of the 256 cells at a time instant t.
			mean_perimeter(t) = sum_perimeter/m  !! mean perimeter of the 256 cells at a time instant t.
			mean_SI(t) = sum_SI/m            !! mean shape-index of the 256 cells at a time instant t.  
			!write(11,*)d,area_frac,mean_perimeter,mean_area,mean_SI
			!d=d+5000
			sum_mean_area = sum_mean_area + mean_area(t)
			sum_mean_perimeter = sum_mean_perimeter + mean_perimeter(t)
			sum_mean_SI = sum_mean_SI + mean_SI(t)
			sum_area_frac = sum_area_frac + area_frac(t)  			               
		else

			do l=1,m
				do i=1,n
				read(10,*)b,b,b,b,b
				end do
			end do
		end if

	end do

	timeavg_area(j) = sum_mean_area/t
	timeavg_perimeter(j) = sum_mean_perimeter/t
	timeavg_SI(j) = sum_mean_SI/t
	timeavg_area_frac(j) = sum_area_frac/t

	sum_timeavg_area = sum_timeavg_area + timeavg_area(j)
	sum_sq_timeavg_area = sum_sq_timeavg_area + timeavg_area(j)*timeavg_area(j)
	sum_timeavg_perimeter = sum_timeavg_perimeter + timeavg_perimeter(j)
	sum_sq_timeavg_perimeter = sum_sq_timeavg_perimeter + timeavg_perimeter(j)*timeavg_perimeter(j)
	sum_timeavg_SI = sum_timeavg_SI + timeavg_SI(j)
	sum_sq_timeavg_SI = sum_sq_timeavg_SI + timeavg_SI(j)*timeavg_SI(j)
	sum_timeavg_area_frac = sum_timeavg_area_frac + timeavg_area_frac(j)
	sum_sq_timeavg_area_frac = sum_sq_timeavg_area_frac + timeavg_area_frac(j)*timeavg_area_frac(j)

	write(25,*)Kadh,timeavg_perimeter(j),timeavg_area(j),timeavg_SI(j),timeavg_area_frac(j) !!for every ensemble, it stores the values
	!write(11,*)j,timeavg_area_frac(j)
	end do
	
	!ensavg_area = sum_timeavg_area/jm
	!ensavg_sq_area = sum_sq_timeavg_area/jm
	!std_dev_area = dsqrt(ensavg_sq_area - ensavg_area*ensavg_area)
	!ensavg_perimeter = sum_timeavg_perimeter/jm
	!ensavg_sq_perimeter = sum_sq_timeavg_perimeter/jm
	!std_dev_perimeter = dsqrt(ensavg_sq_perimeter - ensavg_perimeter*ensavg_perimeter)
	!ensavg_SI = sum_timeavg_SI/jm
	!ensavg_sq_SI = sum_sq_timeavg_SI/jm
	!std_dev_SI = dsqrt(ensavg_sq_SI - ensavg_SI*ensavg_SI)
	!ensavg_area_frac = sum_timeavg_area_frac/jm
	!ensavg_sq_area_frac = sum_sq_timeavg_area_frac/jm
	!std_dev_area_frac = dsqrt(ensavg_sq_area_frac - ensavg_area_frac*ensavg_area_frac)
	!write(11,*)'#','Avg perim',ensavg_perimeter,'Avg area',ensavg_area,'Avg SI',ensavg_SI,'Avg area_frac',ensavg_area_frac
	!write(11,*)'#','Std perim',std_dev_perimeter,'Std area',std_dev_area,'Std SI',std_dev_SI,'Std area_frac',std_dev_area_frac
	!write(12,*)Kadh,ensavg_perimeter,std_dev_perimeter,ensavg_area,std_dev_area,&
		!& ensavg_SI,std_dev_SI,ensavg_area_frac,std_dev_area_frac
	!close(11)
	!close(12)
	call cpu_time(t2)
        write(*,*)'time',t2-t1
	end
