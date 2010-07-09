/* $Id: cext_rriext.c 314 2010-07-09 17:38:41Z mueller $
 *
 * Copyright 2007- by Walter F.J. Mueller <W.F.J.Mueller@gsi.de>
 *
 * This program is free software; you may redistribute and/or modify it under
 * the terms of the GNU General Public License as published by the Free
 * Software Foundation, either version 2, or at your option any later version.
 *
 * This program is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY, without even the implied warranty of MERCHANTABILITY
 * or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
 * for complete details.
 *
 *  Revision History: 
 * Date         Rev  Vers    Comment
 * 2007-11-18    96   1.2    add 'read before write' logic to avoid deadlocks
 *                           under cygwin broken fifo (size=1 !) implementation
 * 2007-10-19    90   1.1    add trace option, controlled by setting an
 *                           the environment variable CEXT_RRIEXT_TRACE=1
 * 2007-09-23    84   1.0    Initial version 
 */ 

#include <unistd.h>
#include <errno.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <stdio.h>
#include <sched.h>
#include <stdlib.h>
#include <string.h>

#define CPREF 0x80
#define CESC  (CPREF|0x0f)
#define QRBUFSIZE 1024

static int fd_rx = -1;
static int fd_tx = -1;

static int io_trace = 0;

static char qr_buf[QRBUFSIZE];
static int  qr_pr  = 0;
static int  qr_pw  = 0;
static int  qr_nb  = 0;
static int  qr_eof = 0;
static int  qr_err = EAGAIN;

/* returns:
 *   <0          if error
 *   >=0 <=0xff  normal data
 *   == 0x100    idle
 *   0x1aahhll   if side band message seen
 *
 */

/* returns
   0 if EGAIN or 
 */

static void cext_dotrace(const char *text, int dat)
{
  int i;
  int mask = 0x80;
  printf("cext_rriext-I: %s   ", text);
  for (i=0; i<8; i++) {
    printf("%c", (dat&mask)?'1':'0' );
    mask >>= 1;
  }
  printf("\n");
}

static void cext_doread()
{
  char buf[1];
  ssize_t nbyte;
  nbyte = read(fd_rx, buf, 1);
  if (nbyte < 0) {
    qr_err = errno;
  } else if (nbyte == 0) {
    qr_err = EAGAIN;
    qr_eof = 1;
  } else {
    qr_err = EAGAIN;
    if (qr_nb < QRBUFSIZE) {
      if (io_trace) cext_dotrace("rcv8", (unsigned char) buf[0]);
      qr_buf[qr_pw++] = buf[0];
      if (qr_pw >= QRBUFSIZE) qr_pw = 0;
      qr_nb += 1;
    } else {
      printf("Buffer overflow\n"); /* FIXME: better error handling */
    }
  }
}

int cext_getbyte(int clk)
{
  char buf[1];
  ssize_t nbyte;
  int irc;
  int tdat;
  char* env_val;

  static int odat;
  static int nidle = 0;
  static int ncesc = 0;
  static int nside = -1;

  if (fd_rx < 0) {		/* fifo's not yet opened */
    fd_rx = open("tb_rriext_fifo_rx", O_RDONLY|O_NONBLOCK);
    if (fd_rx <= 0) {
      perror("cext_rriext-E: failed to open tb_rriext_fifo_rx");
      return -2;
    }
    printf("cext_rriext-I: connected to tb_rriext_fifo_rx\n");
    fd_tx = open("tb_rriext_fifo_tx", O_WRONLY);
    if (fd_tx <= 0) {
      perror("cext_rriext-E: failed to open tb_rriext_fifo_tx");
      return -2;
    }
    printf("cext_rriext-I: connected to tb_rriext_fifo_tx\n");
    nidle = 0;
    ncesc = 0;
    nside = -1;

    io_trace = 0;
    env_val = getenv("CEXT_RRIEXT_TRACE");
    if (env_val && strcmp(env_val, "1") == 0) {
      io_trace = 1;
    }
    
  }

  cext_doread();

  if (qr_nb == 0) {		            /* no character to be processed */
    if (qr_eof != 0) {		            /* EOF seen */
      if (ncesc >= 2) {			    /*  two+ CESC seen  ? */
	printf("cext_rriext-I: seen EOF, wait for reconnect\n");
	close(fd_rx);
	close(fd_tx);
	fd_rx = -1;
	fd_tx = -1;
	usleep(500000);			    /* wait 0.5 sec */
	return 0x100;			    /* return idle, will reconnect */
      }
    
      printf("cext_rriext-I: seen EOF, schedule clock stop and exit\n");
      return -1;			    /* signal EOF seen */
    } else if (qr_err == EAGAIN) {          /* nothing read, return idle */
      if (nidle < 8 || (nidle%1024)==0) {
	irc = sched_yield();
	if (irc < 0) perror("cext_rriext-W: sched_yield failed");
      }
      nidle += 1;
      return 0x100;
    } else {			            /* must be a read error */
      errno = qr_err;
      perror("cext_rriext-E: read error on tb_rriext_fifo_rx");
      return -3;
    }
  }

  nidle = 0;
  tdat = (unsigned char) qr_buf[qr_pr++];
  if (qr_pr >= QRBUFSIZE) qr_pr = 0;
  qr_nb -= 1;
  
  if (tdat == CESC) {
    ncesc += 1;
    if (ncesc == 2) nside = 0;
  } else {
    ncesc = 0;
  }

  switch (nside) {
  case -1:				    /* normal data */
    return tdat;
  case 0:				    /* 2nd CESC, return it */
    nside += 1;
    return tdat;
  case 1:				    /* get ADDR byte */
    nside += 1;
    odat = 0x1000000 | (tdat<<16);
    return 0x100;
  case 2:				    /* get DL byte */
    nside += 1;
    odat |= tdat;
    return 0x100;
  case 3:				    /* get DH byte */
    nside = -1;
    odat |= tdat<<8;
    return odat;
  }  
}

int cext_putbyte(int dat) 
{
  char buf[1];
  ssize_t nbyte;

  cext_doread();

  if (io_trace) cext_dotrace("snd8", dat);

  buf[0] = (unsigned char) dat;
  nbyte = write(fd_tx, buf, 1);

  if (nbyte < 0) {
    perror("cext_rriext-E: write error on tb_rriext_fifo_tx");
    return -3;
  }

  return 0;
}
