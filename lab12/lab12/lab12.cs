using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

using System.Data;
using System.Data.SqlClient;
using System.Data.Common;
using System.Configuration;


namespace lab12
{
    class lab12
    {
        static void Print(string tablename, SqlConnection connection)
        {
            SqlCommand command = new SqlCommand("SELECT * FROM " + tablename, connection);
            //SqlParameter param = new SqlParameter("@Table", SqlDbType.NVarChar);
            //param.Value=tablename;
            //command.Parameters.Add(param);
            //myDataAdapter.InsertCommand.Parameters.Add("@Table", SqlDbType.NVarChar, 0, tablename);

            Console.WriteLine("{0}", command.CommandText);
            //Console.WriteLine("{0}={1}", param.ParameterName, param.Value);
            Console.WriteLine();
            SqlDataReader datareader;

            datareader = command.ExecuteReader();

            for (int i = 0; i < datareader.FieldCount; i++)
            {
                Console.Write(datareader.GetName(i).ToString() + "\t");
            }
            Console.WriteLine();
            while (datareader.Read())
            {
                for (int i = 0; i < datareader.FieldCount; i++)
                {
                    int L = ((datareader.GetName(i).ToString().Length / 8) + 1) * 8;
                    int F = datareader.GetValue(i).ToString().Length;
                    int T = 0;
                    if (L >= F)
                    {
                        T = (L - F + 7) / 8;
                    }
                    Console.Write(datareader.GetValue(i).ToString());
                    for (int j = 0; j < T; j++)
                    {
                        Console.Write("\t");
                    }
                }
                Console.WriteLine();
            }
            Console.WriteLine();
            datareader.Close();
        }

        static void Insert(string SName, int SAge, string SCountry, int SConfig, SqlConnection connection)
        {
            SqlCommand command = new SqlCommand("INSERT INTO Profiles VALUES(@Name, @Age, @Country, @Config)", connection);

            SqlParameter PName = new SqlParameter("@Name", SqlDbType.NVarChar);
            PName.Value = SName;
            command.Parameters.Add(PName);

            SqlParameter PAge = new SqlParameter("@Age", SqlDbType.Int);
            PAge.Value = SAge;
            command.Parameters.Add(PAge);

            SqlParameter PCountry = new SqlParameter("@Country", SqlDbType.NVarChar);
            PCountry.Value = SCountry;
            command.Parameters.Add(PCountry);

            SqlParameter PConfig = new SqlParameter("@Config", SqlDbType.Int);
            PConfig.Value = SConfig;
            command.Parameters.Add(PConfig);

            Console.WriteLine("{0}", command.CommandText);
            Console.Write("Param string: " + SName);
            Console.Write(", " + SAge.ToString());
            Console.Write(", " + SCountry);
            Console.Write(", " + SConfig.ToString());
            Console.WriteLine();
            //Console.WriteLine("{0}={1}", param.ParameterName, param.Value);
            Console.WriteLine();
            SqlDataReader datareader;

            command.ExecuteNonQuery();
            Console.WriteLine("Insert success!");

            Console.WriteLine();
        }

        static void Delete(string SName, SqlConnection connection)
        {
            SqlCommand command = new SqlCommand("DELETE FROM Profiles WHERE ProfileName=@Name", connection);

            SqlParameter PName = new SqlParameter("@Name", SqlDbType.NVarChar);
            PName.Value = SName;
            command.Parameters.Add(PName);

            Console.WriteLine("{0}", command.CommandText);
            Console.Write("Param string: " + SName);
            Console.WriteLine();

            //Console.WriteLine("{0}={1}", param.ParameterName, param.Value);
            Console.WriteLine();
            SqlDataReader datareader;

            command.ExecuteNonQuery();
            Console.WriteLine("Delete success!");

            Console.WriteLine();
        }

        static void Main(string[] args)
        {
            bool connectedlayer;
            connectedlayer = false;
            // connectedlayer = true;
            try{
                try
                {
                    SqlConnection connection = new SqlConnection(ConfigurationManager.ConnectionStrings["NuConn"].ConnectionString);
                    connection.Open();
                    if(connectedlayer)
                    {
                        Console.WriteLine("Connected layer...\n");
                        
                        Print("Profiles", connection);
                        Console.ReadKey();
                        
                        Print("Configs", connection);
                        Console.ReadKey();
                        
                        Insert("Mike", 19, "Russia", 2, connection);
                        Console.ReadKey();
                        Print("Profiles", connection);
                        Console.ReadKey();
                        
                        Delete("Mike", connection);
                        Console.ReadKey();
                        Print("Profiles", connection);
                        Console.ReadKey();
                        
                    }
                    else
                    {
                        //Begin
                        Console.WriteLine("Disconnected layer...\n");
                        Print("Profiles", connection);
                        Console.ReadKey();
                        
                        //SELECT
                        SqlCommand selectCmd = new SqlCommand("SELECT * FROM Profiles", connection);
                        
                        //INSERT
                        SqlCommand insertCmd = new SqlCommand("INSERT INTO Profiles VALUES(@Name, @Age, @Country, @Config)", connection);
                        SqlParameterCollection parcol = insertCmd.Parameters;
                        parcol.Add("@Name",    SqlDbType.NVarChar, 40, "ProfileName");
                        parcol.Add("@Age",     SqlDbType.Int,      4,  "ProfileAge");
                        parcol.Add("@Country", SqlDbType.NVarChar, 40, "ProfileCountry");
                        parcol.Add("@Config",  SqlDbType.Int,      4,  "ConfigID");
                        
                        //DELETE
                        SqlCommand deleteCmd = new SqlCommand("DELETE FROM Profiles WHERE ProfileID=@ID", connection);
                        parcol = deleteCmd.Parameters;
                        parcol.Add("ID", SqlDbType.Int, 0, "ProfileID");
                        
                        //UPDATE
                        SqlCommand updateCmd = new SqlCommand("UPDATE Profiles SET "+
                                                              "ProfileName=@NewName, ProfileAge=@NewAge, ProfileCountry=@NewCountry, ConfigID=@NewConfig"+
                                                              " WHERE "+
                                                              "ProfileName=@OldName AND ProfileAge=@OldAge AND ProfileCountry=@OldCountry AND ConfigID=@OldConfig"
                                                                , connection);
                        parcol = updateCmd.Parameters;
                        parcol.Add("@NewName",    SqlDbType.NVarChar, 40, "ProfileID");
                        parcol.Add("@NewAge",     SqlDbType.Int,      4,  "ProfileAge");
                        parcol.Add("@NewCountry", SqlDbType.NVarChar, 40, "ProfileCountry");
                        parcol.Add("@NewConfig",  SqlDbType.Int,      4,  "ConfigID");
                        
                        SqlParameter temp;
                        temp = parcol.Add("@OldName", SqlDbType.NVarChar,    40, "ProfileName");
                        temp.SourceVersion = DataRowVersion.Original;
                        temp = parcol.Add("@OldAge", SqlDbType.Int,          4,  "ProfileAge");
                        temp.SourceVersion = DataRowVersion.Original;
                        temp = parcol.Add("@OldCountry", SqlDbType.NVarChar, 40, "ProfileCountry");
                        temp.SourceVersion = DataRowVersion.Original;
                        temp = parcol.Add("@OldConfig", SqlDbType.Int,       4,  "ConfigID");
                        temp.SourceVersion = DataRowVersion.Original;
                        
                        //DATA ADAPTER
                        SqlDataAdapter dataadapter = new SqlDataAdapter();
                        DataSet dataset = new DataSet();
                        dataadapter.SelectCommand = selectCmd;
                        dataadapter.InsertCommand = insertCmd;
                        dataadapter.DeleteCommand = deleteCmd;
                        dataadapter.UpdateCommand = updateCmd;
                        
                        //DATA SET CHANGING
                        dataadapter.Fill(dataset, "Profiles"); //required: select command
                        int N = dataset.Tables["Profiles"].Rows.Count;
                        
                        bool toggleAddDel;
                        toggleAddDel = false;
                        // toggleAddDel = true;
                        
                        if(toggleAddDel){
                            DataRow User1 = dataset.Tables["Profiles"].NewRow();
                            User1["ProfileName"] = "DAVEXXX";
                            User1["ProfileAge"] = 33;
                            User1["ConfigID"] = 1;
                            dataset.Tables["Profiles"].Rows.Add(User1);
                            N++;
                            
                            DataRow User2 = dataset.Tables["Profiles"].NewRow();
                            User2["ProfileName"] = "DAVEXXX";
                            User2["ProfileCountry"] = "Holywood";
                            User2["ConfigID"] = 1;
                            dataset.Tables["Profiles"].Rows.Add(User2);
                            N++;
                        }
                        
                        string S = dataset.Tables["Profiles"].Rows[1]["ProfileAge"].ToString();
                        int I = 28028 - Convert.ToInt32(S);
                        //I = 28;
                        dataset.Tables["Profiles"].Rows[1]["ProfileAge"] = I.ToString();
                        
                        // dataadapter.Update(dataset, "Profiles"); //required: TableMapping or DataTable
                        // dataset.Tables["Profiles"].AcceptChanges();
                        
                        if(!toggleAddDel){
                            DataRow row;
                            for(int i = 0; i < N; i++){
                                row = dataset.Tables["Profiles"].Rows[i];
                                if(String.Compare(row["ProfileAge"].ToString(), "33") == 0){
                                    row.Delete();
                                    Console.WriteLine("Deleting {0}", i);
                                    continue;
                                }
                                if(String.Compare(row["ProfileCountry"].ToString(), "Holywood") == 0){
                                    row.Delete();
                                    Console.WriteLine("Deleting {0}", i);
                                    continue;
                                }
                            }
                        }
                        
                        dataadapter.Update(dataset, "Profiles"); //required: TableMapping or DataTable
                        
                        //End
                        Print("Profiles", connection);
                        Console.ReadKey();
                    }
                }
                catch (Exception e)
                {
                    Console.WriteLine("Crash!");
                    Console.WriteLine(e.Message);
                }
                // finally
                // {
                    // connection.Close();
                // }
            }
            catch (Exception e)
            {
                Console.WriteLine("Crash!");
                Console.WriteLine(e.Message);
            }
            Console.WriteLine("Press any key to exit...");
            Console.ReadKey();
        }
    }
}


/*
--------ExecReaded...
--------connection op/cl

*/
