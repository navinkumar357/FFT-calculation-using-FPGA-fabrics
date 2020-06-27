`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Original file prepared by Mahdad Davari
//////////////////////////////////////////////////////////////////////////////////


module mat_mul_tb # 
    (
        parameter integer DATA_WIDTH = 32,        
        parameter integer MATRIX_DIMENSION_LOG_2 = 6 // for debug use a smaller size
    )
    (

    );
    
    reg  s00_axi_aclk;
    reg  s00_axi_aresetn;

	// Ports of Axi Slave Bus Interface S00_AXIS
    wire  s00_axis_tready;
    reg [DATA_WIDTH-1 : 0] s00_axis_tdata;
    reg [(DATA_WIDTH/8)-1 : 0] s00_axis_tstrb;
    reg  s00_axis_tlast;
    reg  s00_axis_tvalid;

    // Ports of Axi Master Bus Interface M00_AXIS
    wire  m00_axis_tvalid;
    wire [DATA_WIDTH-1 : 0] m00_axis_tdata;
    wire [(DATA_WIDTH/8)-1 : 0] m00_axis_tstrb;
    wire  m00_axis_tlast;
    reg  m00_axis_tready;
    
    reg sel;
    reg start;
    
    integer row;
    integer column;
    integer count;
    
    integer matA [0 : (2**MATRIX_DIMENSION_LOG_2)**2-1];
    integer matB [0 : (2**MATRIX_DIMENSION_LOG_2)**2-1];
    integer matRSW [0 : (2**MATRIX_DIMENSION_LOG_2)**2-1];
    integer matRHW [0 : (2**MATRIX_DIMENSION_LOG_2)**2-1];
    
    mat_mul # (
    .DIM_LOG(MATRIX_DIMENSION_LOG_2),
    .DATA_WIDTH(DATA_WIDTH)
    ) accelerator (
    .s00_axi_aclk(s00_axi_aclk),
    .s00_axi_aresetn(s00_axi_aresetn),
    .s00_axis_tready(s00_axis_tready),
    .s00_axis_tdata(s00_axis_tdata),
    .s00_axis_tlast(s00_axis_tlast),
    .s00_axis_tvalid(s00_axis_tvalid),
    .m00_axis_tvalid(m00_axis_tvalid),
    .m00_axis_tdata(m00_axis_tdata),
    .m00_axis_tstrb(m00_axis_tstrb),
    .m00_axis_tlast(m00_axis_tlast),
    .m00_axis_tready(m00_axis_tready),
    .sel(sel),
    .start(start)
    );
    
    always
        #10 s00_axi_aclk = ~s00_axi_aclk;
        
    initial begin
        s00_axi_aclk = 1;
        s00_axi_aresetn = 0;
        s00_axis_tdata = 0;
        s00_axis_tstrb = 4'hf;
        s00_axis_tlast = 0;
        s00_axis_tvalid = 0;
        m00_axis_tready = 0;
        sel = 0;
        start = 0;
        row = 0;
        column = 0;
        count = 0;
        
        // initialise the matrices; for debug use $urandom%10 to have unsigned values less than 10;
        for (row = 0; row < 2**MATRIX_DIMENSION_LOG_2; row = row + 1) begin
            for (column = 0; column < 2**MATRIX_DIMENSION_LOG_2; column = column + 1) begin
                matA [(2**MATRIX_DIMENSION_LOG_2)*row + column] = $urandom;
                matB [(2**MATRIX_DIMENSION_LOG_2)*row + column] = $urandom;
                matRSW [(2**MATRIX_DIMENSION_LOG_2)*row + column] = 0;
                matRHW [(2**MATRIX_DIMENSION_LOG_2)*row + column] = 0;
            end
        end
        
        // multiply the matrices for comparison with hardware result
        for (row = 0; row < 2**MATRIX_DIMENSION_LOG_2; row = row + 1)
            for (column = 0; column < 2**MATRIX_DIMENSION_LOG_2; column = column + 1)
                for (count = 0; count < 2**MATRIX_DIMENSION_LOG_2; count = count + 1)
                    matRSW [(2**MATRIX_DIMENSION_LOG_2)*row + column] = matRSW [(2**MATRIX_DIMENSION_LOG_2)*row + column] + matA [(2**MATRIX_DIMENSION_LOG_2)*row + count] * matB [(2**MATRIX_DIMENSION_LOG_2)*count + column];
        #20
        s00_axi_aresetn = 1;
        count = 0;
        
        // send the two matrices using the AXI Stream protocol
        repeat (2) begin
            #20
            s00_axis_tvalid = 1;
            for (row = 0; row < 2**MATRIX_DIMENSION_LOG_2; row = row + 1) begin
                for (column = 0; column < 2**MATRIX_DIMENSION_LOG_2; column = column + 1) begin
                    s00_axis_tdata = (sel == 0) ? matA [(2**MATRIX_DIMENSION_LOG_2)*row + column] : matB [(2**MATRIX_DIMENSION_LOG_2)*row + column];
                    
                    // set the last signal when sending the last data item
                    if (row == 2**MATRIX_DIMENSION_LOG_2 - 1 && column == 2**MATRIX_DIMENSION_LOG_2 - 1)
                        s00_axis_tlast = 1;
                    #20;
                    
                    // wait until the slave is ready to read the data
                    while (!s00_axis_tready) begin
                        #20;
                    end
                end
            end
            
            s00_axis_tlast = 0;
            s00_axis_tvalid = 0;
            
            // send the other matrix
            sel = 1;
        end
        
        // start the accelerator
        #20
        start = 1;
        #20
        start = 0;
        
        // wait for the reslt to arrive from the accelerator
        m00_axis_tready = 1;
        
        row = 0;
        column = 0;
        
        while (!m00_axis_tlast) begin // exit if last data already received
            #20;
            if (m00_axis_tvalid == 1) begin // valid data on the bus
                matRHW [(2**MATRIX_DIMENSION_LOG_2)*row + column] = m00_axis_tdata;
                column = column + 1;
            end
            if (column == 2**MATRIX_DIMENSION_LOG_2) begin
                column = 0;
                row = row + 1;
            end
        end
        
        m00_axis_tready = 0;
        count = 0;
        
        // compare the hardware and software results
        for (row = 0; row < 2**MATRIX_DIMENSION_LOG_2; row = row + 1)
            for (column = 0; column < 2**MATRIX_DIMENSION_LOG_2; column = column + 1)
                if (matRSW [(2**MATRIX_DIMENSION_LOG_2)*row + column] != matRHW [(2**MATRIX_DIMENSION_LOG_2)*row + column] 
                     || ^matRHW [(2**MATRIX_DIMENSION_LOG_2)*row + column] === 1'bX) begin
                    count = count + 1;
                    $display ("HW/SW result mismatch! A[%d][%d]=%d; B[%d][%d]=%d; res_sw=%d; res_hw=%d", row, column, matA[row][column], row, column, matB[row][column], matRSW[row][column], matRHW[row][column]);
                end

       if (count == 0)
            $display ("HW/SW result match!");
       
       $stop;
       
    end
    
endmodule
